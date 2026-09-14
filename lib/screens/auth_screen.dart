import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/phone.dart';
import '../widgets/app_logo.dart';

class AuthScreen extends StatefulWidget {
  /// When true, shows a close button and pops with `true` after successful login.
  final bool isModal;

  /// Opens directly on the registration form. Used wherever the user has no
  /// account yet — buying PRO, for example — so they aren't dropped on a
  /// sign-in form they can't complete.
  final bool startOnSignUp;

  const AuthScreen({
    super.key,
    this.isModal = false,
    this.startOnSignUp = false,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Sign-in accepts a phone number or a legacy email address.
  final _identifierController = TextEditingController();

  /// Sign-up is phone-only — no name, username or email is asked for.
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late bool _isSignUp = widget.startOnSignUp;
  String? _errorMessage;
  String? _infoMessage;

  /// Whether what has been typed reads as a phone number or an email.
  IdentifierKind _identifierKind = IdentifierKind.empty;

  @override
  void dispose() {
    _identifierController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? v, String lang) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return AppStrings.get('auth_identifier_required', lang);
    if (UzPhone.identifierToAuthEmail(value) == null) {
      return AppStrings.get('auth_error_identifier_invalid', lang);
    }
    return null;
  }

  String? _validatePhone(String? v, String lang) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return AppStrings.get('auth_phone_required', lang);
    if (UzPhone.normalize(value) == null) {
      return AppStrings.get('auth_error_phone_invalid', lang);
    }
    return null;
  }

  String? _validatePassword(String? v, String lang) {
    final value = v ?? '';
    if (value.isEmpty) return AppStrings.get('auth_password_required', lang);
    if (_isSignUp && value.length < UzPhone.minPasswordLength) {
      return AppStrings.get('auth_error_weak_password', lang);
    }
    return null;
  }

  String? _validateConfirmPassword(String? v, String lang) {
    if ((v ?? '') != _passwordController.text) {
      return AppStrings.get('auth_error_password_mismatch', lang);
    }
    return null;
  }

  void _onIdentifierChanged(String value) {
    final kind = UzPhone.classify(value);
    if (kind == _identifierKind) return;
    setState(() => _identifierKind = kind);
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _infoMessage = null;
    });
  }

  Future<void> _openTelegramSupport() async {
    final uri = Uri.parse(SupabaseConfig.paymentTelegramUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      /* Telegram not installed — the handle is shown as text anyway. */
    }
  }

  /// Email accounts get a real reset link; phone accounts can only be helped
  /// by the admin, since `@pro.com` receives no mail.
  Future<void> _handleForgotPassword() async {
    final lang = context.read<LanguageProvider>().lang;
    final kind = UzPhone.classify(_identifierController.text);

    if (kind != IdentifierKind.email) {
      setState(() {
        _errorMessage = null;
        _infoMessage = AppStrings.get('reset_needs_email', lang);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final errKey = await context.read<AuthProvider>().sendPasswordReset(
      _identifierController.text,
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (errKey == null) {
        _infoMessage = AppStrings.get('reset_email_sent', lang);
      } else {
        _errorMessage = AppStrings.get(errKey, lang);
      }
    });
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final lang = context.read<LanguageProvider>().lang;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final errKey = _isSignUp
        ? await auth.signUpWithPhone(
            phone: _phoneController.text,
            password: _passwordController.text,
          )
        : await auth.signInWithIdentifier(
            identifier: _identifierController.text,
            password: _passwordController.text,
          );

    if (!mounted) return;

    if (errKey == null) {
      if (widget.isModal) {
        Navigator.pop(context, true);
        return;
      }
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = AppStrings.get(errKey, lang);
    });
  }

  Future<void> _handleGoogle() async {
    final lang = context.read<LanguageProvider>().lang;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final errKey = await context.read<AuthProvider>().signInWithGoogle();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (errKey != null) _errorMessage = AppStrings.get(errKey, lang);
      // On success the browser takes over; the session arrives through the
      // deep link and AuthGate rebuilds on its own.
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      // KEYBOARD PERFORMANCE — READ BEFORE CHANGING.
      //
      // This used to be `false`, with the keyboard height added by hand as
      // bottom padding via `MediaQuery.viewInsetsOf(context)`. That call made
      // THIS build method depend on the inset, so every one of the ~15 frames
      // of the keyboard animation rebuilt the entire form: logo, headings,
      // three fields, both buttons, the divider, the hint. That is the
      // stutter people saw opening and closing the keyboard.
      //
      // Letting the Scaffold do it moves the work from rebuild to relayout of
      // one scroll view, which is an order of magnitude cheaper and is what
      // Flutter optimises for.
      resizeToAvoidBottomInset: true,
      appBar: widget.isModal
          ? AppBar(
              title: Text(s(_isSignUp ? 'sign_up_title' : 'sign_in_title')),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const AppHeaderLogo(height: 48),
                        const SizedBox(height: 8),
                        Text(
                          s(_isSignUp ? 'sign_up_title' : 'sign_in_title'),
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textM(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Google first on sign-in: most existing accounts were
                  // created that way on the website and have no password, so
                  // burying this button under the password form would leave
                  // them staring at "invalid credentials".
                  if (!_isSignUp) ...[
                    _GoogleButton(
                      label: s('continue_with_google'),
                      enabled: !_isLoading,
                      onTap: _handleGoogle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s('google_hint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textM(context),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _OrDivider(label: s('or')),
                    const SizedBox(height: 18),
                  ],
                  if (_isSignUp)
                    _PhoneField(
                      controller: _phoneController,
                      label: s('phone_number'),
                      enabled: !_isLoading,
                      validator: (v) => _validatePhone(v, lang),
                    )
                  else ...[
                    _LabeledField(
                      controller: _identifierController,
                      label: s('phone_or_email'),
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      validator: (v) => _validateIdentifier(v, lang),
                      enabled: !_isLoading,
                      onChanged: _onIdentifierChanged,
                    ),
                    // Says out loud how the entry will be used, so a phone
                    // number is never silently treated as an email.
                    _IdentifierHint(kind: _identifierKind, lang: lang),
                  ],
                  const SizedBox(height: 14),
                  _LabeledField(
                    controller: _passwordController,
                    label: _isSignUp ? s('password_min_8') : s('password'),
                    icon: Icons.lock_outline,
                    isPassword: _obscurePassword,
                    autofillHints: [
                      _isSignUp
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    textInputAction: _isSignUp
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: (_) => _isSignUp ? null : _handleSubmit(),
                    validator: (v) => _validatePassword(v, lang),
                    enabled: !_isLoading,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppTheme.textM(context),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 14),
                    _LabeledField(
                      controller: _confirmPasswordController,
                      label: s('password_repeat'),
                      icon: Icons.lock_reset_outlined,
                      isPassword: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleSubmit(),
                      validator: (v) => _validateConfirmPassword(v, lang),
                      enabled: !_isLoading,
                    ),
                  ],
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          s('forgot_password'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    _InlineMessage(
                      text: _errorMessage!,
                      color: AppTheme.error,
                      icon: Icons.error_outline,
                    ),
                  if (_infoMessage != null)
                    _InlineMessage(
                      text: _infoMessage!,
                      color: AppTheme.success,
                      icon: Icons.mark_email_read_outlined,
                    ),
                  if (_isSignUp)
                    _InlineMessage(
                      text: s('signup_phone_hint'),
                      color: AppTheme.blue,
                      icon: Icons.info_outline_rounded,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: AppTheme.blueGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.blue.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleSubmit,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    s(_isSignUp ? 'sign_up' : 'sign_in'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // On sign-up Google stays below: a new user is here to
                  // register with a phone number, and Google is the alternative.
                  if (_isSignUp) ...[
                    const SizedBox(height: 14),
                    _GoogleButton(
                      label: s('continue_with_google'),
                      enabled: !_isLoading,
                      onTap: _handleGoogle,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : _openTelegramSupport,
                      icon: const Icon(Icons.telegram_rounded, size: 16),
                      label: Text(
                        '${s('need_help')} — @avtosmart1',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _toggleMode,
                      child: Text.rich(
                        TextSpan(
                          text:
                              '${s(_isSignUp ? 'have_account_question' : 'no_account_question')} ',
                          style: TextStyle(color: AppTheme.textM(context)),
                          children: [
                            TextSpan(
                              text: s(
                                _isSignUp ? 'sign_in' : 'create_account_cta',
                              ),
                              style: const TextStyle(
                                color: AppTheme.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Divider(color: AppTheme.border(context)));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, color: AppTheme.textM(context)),
          ),
        ),
        line,
      ],
    );
  }
}

/// Tells the user how their entry was understood — phone or email — so a
/// mistyped number never silently gets sent as an email address.
class _IdentifierHint extends StatelessWidget {
  final IdentifierKind kind;
  final String lang;

  const _IdentifierHint({required this.kind, required this.lang});

  @override
  Widget build(BuildContext context) {
    final (icon, key, color) = switch (kind) {
      IdentifierKind.phone => (
        Icons.phone_iphone_rounded,
        'identifier_is_phone',
        AppTheme.success,
      ),
      IdentifierKind.email => (
        Icons.mail_outline_rounded,
        'identifier_is_email',
        AppTheme.success,
      ),
      IdentifierKind.invalid => (
        Icons.error_outline_rounded,
        'identifier_unknown',
        AppTheme.orange,
      ),
      IdentifierKind.empty => (null, null, null),
    };

    if (icon == null || key == null || color == null) {
      return const SizedBox(height: 6);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AppStrings.get(key, lang),
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Phone field with a fixed `+998` prefix — the user types nine digits and
/// they are grouped as `90 123 45 67` while typing.
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  const _PhoneField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      textInputAction: TextInputAction.next,
      inputFormatters: const [UzPhoneInputFormatter()],
      validator: validator,
      style: TextStyle(
        color: AppTheme.textP(context),
        fontSize: 15,
        letterSpacing: 0.5,
      ),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
          child: Text(
            '+${UzPhone.countryCode}',
            style: TextStyle(
              color: AppTheme.textP(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _GoogleButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: AppTheme.textP(context),
          side: BorderSide(color: AppTheme.border(context)),
        ),
        icon: const _GoogleGlyph(),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Small "G" mark drawn from theme colors — avoids shipping a brand asset.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _InlineMessage({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final Widget? suffix;
  final bool enabled;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.suffix,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: isPassword,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: validator,
      autocorrect: false,
      enableSuggestions: !isPassword,
      style: TextStyle(color: AppTheme.textP(context), fontSize: 14),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textM(context)),
        suffixIcon: suffix,
      ),
    );
  }
}
