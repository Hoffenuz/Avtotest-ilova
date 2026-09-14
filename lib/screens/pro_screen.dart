import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_strings.dart';
import '../services/payme_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tab_visibility.dart';
import 'auth_screen.dart';
import 'payme_checkout_screen.dart';

class ProScreen extends StatefulWidget {
  final int? tabIndex;

  const ProScreen({super.key, this.tabIndex});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> with WidgetsBindingObserver {
  late Future<List<PaymePlan>> _plansFuture;

  /// Guards against a second checkout being opened while one is running.
  bool _purchasing = false;

  bool _isVisible(BuildContext context) {
    if (widget.tabIndex == null) return true;
    final tabs = TabVisibility.maybeOf(context);
    if (tabs == null) return true;
    return tabs.isTabActive(widget.tabIndex!);
  }

  void _refreshIfVisible() {
    if (!mounted || !_isVisible(context)) return;
    context.read<SubscriptionProvider>().refresh();
  }

  @override
  void initState() {
    super.initState();
    _plansFuture = PaymeService.fetchPlans();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfVisible());
  }

  void _reloadPlans() {
    setState(() => _plansFuture = PaymeService.fetchPlans());
  }

  /// Full purchase flow: sign-in check → Payme checkout → server-side
  /// verification. PRO is never switched on locally; the app only re-reads
  /// `get_user_access_state` until the Payme callback has landed.
  Future<void> _startPurchase(PaymePlan plan, String lang) async {
    if (_purchasing) return;

    final auth = context.read<AuthProvider>();
    final sub = context.read<SubscriptionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    String s(String k) => AppStrings.get(k, lang);

    void notify(String key) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(content: Text(s(key)), duration: const Duration(seconds: 4)),
      );
    }

    // Payment needs an account: the transaction is tied to the user's address.
    // Someone tapping "buy PRO" without an account is almost always a new
    // user, so open registration — the form has a "sign in" link for the rest.
    if (!auth.isLoggedIn) {
      final signedIn = await Navigator.push<bool>(
        context,
        AppTheme.slideRoute(
          const AuthScreen(isModal: true, startOnSignUp: true),
        ),
      );
      if (signedIn != true || !mounted) return;
      await sub.refresh(force: true);
      if (!mounted) return;
      // Carry on with the plan the user originally picked.
      return _startPurchase(plan, lang);
    }

    // A live subscription must not be paid for twice — the server would
    // stack the days, but the user rarely means that.
    if (sub.isPro) {
      notify('pro_already_active');
      return;
    }

    final accountEmail = auth.userEmail;
    if (accountEmail.isEmpty) {
      notify('auth_error_generic');
      return;
    }

    _purchasing = true;
    try {
      final url = PaymeService.buildCheckoutUrl(
        accountEmail: accountEmail,
        amountTiyin: plan.amountTiyin,
        lang: lang,
      );

      final completed = await Navigator.push<bool>(
        context,
        AppTheme.slideRoute(
          PaymeCheckoutScreen(
            checkoutUrl: url,
            planTitle: _planTitle(plan, lang),
          ),
        ),
      );
      if (!mounted) return;

      if (completed != true) {
        // Cancelled — but a payment made in a card app or the browser also
        // lands here, because this screen never saw Payme redirect. Check, and
        // congratulate rather than silently returning if it did go through.
        await sub.refresh(force: true);
        if (!mounted) return;
        if (sub.isPro) {
          await _showActivatedDialog(lang);
        } else {
          // Short watch, not the full three minutes: most of the time this
          // really was a cancel and nothing will arrive.
          sub.watchForActivation(budget: const Duration(seconds: 45));
        }
        return;
      }

      final activated = await _verifyWithLoader(sub, lang);
      if (!mounted) return;

      if (activated) {
        await _showActivatedDialog(lang);
      } else {
        // Not confirmed yet is not the same as failed. Keep checking in the
        // background so PRO switches on by itself when the callback lands,
        // instead of the user having to restart the app to find out.
        notify('payment_pending');
        sub.watchForActivation();
      }
    } finally {
      _purchasing = false;
    }
  }

  /// Polls the access RPC behind a blocking loader.
  Future<bool> _verifyWithLoader(SubscriptionProvider sub, String lang) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final loaderRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VerifyingDialog(lang: lang),
    );
    navigator.push(loaderRoute);

    try {
      return await sub.pollForActivation();
    } finally {
      navigator.removeRoute(loaderRoute);
    }
  }

  Future<void> _showActivatedDialog(String lang) {
    String s(String k) => AppStrings.get(k, lang);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.verified_rounded,
          size: 44,
          color: AppTheme.success,
        ),
        title: Text(s('payment_success_title'), textAlign: TextAlign.center),
        content: Text(s('payment_success_msg'), textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s('great')),
            ),
          ),
        ],
      ),
    );
  }

  String _planTitle(PaymePlan plan, String lang) {
    switch (plan.planName) {
      case 'weekly':
        return AppStrings.get('plan_weekly_title', lang);
      case 'monthly':
        return AppStrings.get('plan_monthly_title', lang);
      case 'quarterly':
        return AppStrings.get('plan_quarterly_title', lang);
      default:
        return '${plan.tariffDays} ${AppStrings.get('n_days', lang)}';
    }
  }

  String _planSubtitle(PaymePlan plan, String lang) {
    switch (plan.planName) {
      case 'weekly':
        return AppStrings.get('plan_weekly_subtitle', lang);
      case 'monthly':
        return AppStrings.get('plan_monthly_subtitle', lang);
      case 'quarterly':
        return AppStrings.get('plan_quarterly_subtitle', lang);
      default:
        return '${plan.tariffDays} ${AppStrings.get('n_days', lang)}';
    }
  }

  String _planButton(PaymePlan plan, String lang) {
    switch (plan.planName) {
      case 'weekly':
        return AppStrings.get('plan_weekly_button', lang);
      case 'monthly':
        return AppStrings.get('plan_monthly_button', lang);
      case 'quarterly':
        return AppStrings.get('plan_quarterly_button', lang);
      default:
        return AppStrings.get('subscribe_pro', lang);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfVisible());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfVisible();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _openTelegram(String lang) async {
    final uri = Uri.parse(SupabaseConfig.paymentTelegramUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get('telegram_open_failed', lang))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get('telegram_open_failed', lang))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(title: Text(s('pro_title')), centerTitle: true),
      body: RefreshIndicator(
        color: AppTheme.orange,
        onRefresh: () => context.read<SubscriptionProvider>().refresh(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // `info` is set together with the premium flag, so this is
              // belt-and-braces — but a `!` here would crash the screen a
              // paying user opens to check their subscription, which is the
              // worst possible place to be brittle.
              if (sub.isPro && sub.info != null)
                _ActiveProBanner(info: sub.info!, lang: lang)
              else
                _ProHeader(loading: sub.loading, lang: lang),

              const SizedBox(height: 20),
              _FeaturesCard(lang: lang),

              // AN ACTIVE SUBSCRIBER IS NOT SHOWN THE PRICE LIST. They have
              // paid; the tariff cards below only led to "your subscription is
              // already active", so the whole sales half of this screen was a
              // dead end that read as the app forgetting they had bought it.
              if (sub.isPro) ...[
                const SizedBox(height: 20),
                _AlreadyProNote(lang: lang),
              ] else ...[
                const SizedBox(height: 24),
                _ChoosePlanHeader(lang: lang),
                const SizedBox(height: 12),

                // Prices come from `payme_plans`, never from the app: Payme
                // rejects any amount its server didn't authorise (-31001).
                FutureBuilder<List<PaymePlan>>(
                  future: _plansFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _PlansPlaceholder();
                    }
                    if (snapshot.hasError) {
                      return _PlansError(lang: lang, onRetry: _reloadPlans);
                    }

                    final plans = snapshot.data ?? const <PaymePlan>[];
                    if (plans.isEmpty) {
                      return _PlansError(lang: lang, onRetry: _reloadPlans);
                    }

                    return Column(
                      children: [
                        for (final plan in plans) ...[
                          _PlanCard(
                            title: _planTitle(plan, lang),
                            subtitle: _planSubtitle(plan, lang),
                            price: plan.formattedSom,
                            currency: s('pro_currency_som'),
                            buttonLabel: _planButton(plan, lang),
                            badge: plan.planName == 'monthly'
                                ? s('plan_monthly_badge')
                                : null,
                            isPrimary: plan.planName == 'monthly',
                            onTap: () => _startPurchase(plan, lang),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _PaymeNote(lang: lang),
              ],

              const SizedBox(height: 16),

              _ContactCard(lang: lang, onTap: () => _openTelegram(lang)),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveProBanner extends StatelessWidget {
  final SubscriptionInfo info;
  final String lang;
  const _ActiveProBanner({required this.info, required this.lang});

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);
    final remaining = info.daysRemaining;
    final expiry = info.expiryDateTashkent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withValues(alpha: 0.18),
            AppTheme.success.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppTheme.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s('pro_active_title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textP(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s('pro_type_pro')} · $remaining ${s('pro_days_left')}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textS(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s('pro_active_expiry')}: $expiry',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textM(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Blocking dialog shown while the Payme callback is being awaited.
class _VerifyingDialog extends StatelessWidget {
  final String lang;
  const _VerifyingDialog({required this.lang});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.orange,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                AppStrings.get('payment_verifying', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlansPlaceholder extends StatelessWidget {
  const _PlansPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 138,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border(context)),
          ),
        ),
      ),
    );
  }
}

class _PlansError extends StatelessWidget {
  final String lang;
  final VoidCallback onRetry;

  const _PlansError({required this.lang, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppTheme.textM(context)),
          const SizedBox(height: 10),
          Text(
            AppStrings.get('plans_load_failed', lang),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppTheme.textM(context)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(AppStrings.get('retry', lang)),
          ),
        ],
      ),
    );
  }
}

/// Reassures the user about where the money goes and that PRO is unlocked by
/// the server, not by the app.
/// Shown in place of the price list once the subscription is active.
class _AlreadyProNote extends StatelessWidget {
  final String lang;
  const _AlreadyProNote({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.success, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.get('pro_all_unlocked', lang),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppTheme.textP(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymeNote extends StatelessWidget {
  final String lang;
  const _PaymeNote({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppTheme.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.get('payme_secure_note', lang),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppTheme.textM(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProHeader extends StatelessWidget {
  final bool loading;
  final String lang;
  const _ProHeader({required this.loading, required this.lang});

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.orange.withValues(alpha: 0.18),
            AppTheme.orange.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppTheme.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s('pro_header_badge'),
                      style: const TextStyle(
                        color: AppTheme.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.orange,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            s('pro_header_title'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textP(context),
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s('pro_header_subtitle'),
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textM(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoosePlanHeader extends StatelessWidget {
  final String lang;
  const _ChoosePlanHeader({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.star_outline_rounded,
          color: AppTheme.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          AppStrings.get('pro_choose_plan', lang),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.textP(context),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String currency;
  final String buttonLabel;
  final String? badge;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.currency,
    required this.buttonLabel,
    this.badge,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isPrimary
        ? AppTheme.orange.withValues(alpha: 0.7)
        : AppTheme.border(context);
    final bg = isPrimary
        ? AppTheme.orange.withValues(alpha: 0.06)
        : AppTheme.card(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: borderColor, width: isPrimary ? 2 : 1),
            boxShadow: AppTheme.isDark(context) || !isPrimary
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.orange.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textP(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textM(context),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textP(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      currency,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textM(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _PlanButton(
                  label: buttonLabel,
                  isPrimary: isPrimary,
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ),
        if (badge != null)
          Positioned(
            top: -10,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppTheme.orangeGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.orange.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PlanButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppTheme.orangeGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppTheme.orange.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textP(context),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  final String lang;
  const _FeaturesCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);
    final perks = [
      s('pro_perk_1'),
      s('pro_perk_2'),
      s('pro_perk_3'),
      s('pro_perk_4'),
      s('pro_perk_5'),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.orange.withValues(alpha: 0.14),
            AppTheme.orange.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.orange.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppTheme.orangeGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s('pro_features_title'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textP(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...perks.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textP(context),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String lang;
  final VoidCallback onTap;
  const _ContactCard({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0088CC).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.telegram_rounded,
                  color: Color(0xFF0088CC),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('pro_contact_subtitle', lang),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textM(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '@avtosmart1',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0088CC),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textM(context)),
            ],
          ),
        ),
      ),
    );
  }
}
