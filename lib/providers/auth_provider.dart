import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../utils/phone.dart';

/// Global authentication state backed by Supabase Auth.
///
/// Sessions are persisted automatically by `supabase_flutter`, so a
/// successful login survives app restarts. This provider listens to
/// `onAuthStateChange` and rebuilds dependent widgets on every signed-in /
/// signed-out event.
class AuthProvider extends ChangeNotifier {
  /// `true` while we're restoring the persisted session at startup.
  bool _bootstrapping = true;

  /// The current Supabase session, if any.
  Session? _session;

  /// Cached profile row for convenience (name, role, …).
  UserProfile? _profile;

  StreamSubscription<AuthState>? _authSub;

  bool get bootstrapping => _bootstrapping;
  bool get isLoggedIn => _session != null;
  Session? get session => _session;
  User? get user => _session?.user;
  String? get userId => _session?.user.id;

  /// The address Supabase Auth knows the user by. For phone accounts this is
  /// the synthetic `998XXXXXXXXX@pro.com` value — needed for API calls (Payme
  /// checkout, password change), never for display.
  String get userEmail => _session?.user.email ?? _profile?.email ?? '';

  String get userName => _profile?.fullName ?? '';

  /// True when the account was created through the phone flow.
  bool get isPhoneAccount => UzPhone.isPhoneAccount(userEmail);

  /// What the profile screen shows as the account identity: a formatted phone
  /// number for phone accounts, the email itself for legacy ones. `@pro.com`
  /// must never reach the UI.
  String get displayIdentity =>
      UzPhone.displayFromAuthEmail(userEmail) ?? userEmail;

  /// Read the persisted session (if any) and start listening for auth
  /// state changes. Must be called once during app startup, after
  /// `SupabaseService.init()`.
  ///
  /// BOOTSTRAPPING MUST END NO MATTER WHAT. `main()` treats a failed Supabase
  /// init as "the user starts signed out" and carries on — but if this method
  /// then threw on the way to `_bootstrapping = false`, the flag would stay
  /// true and AuthGate would show its splash spinner forever. Practice tests
  /// and every reference section work fully offline, so an unreachable backend
  /// has to leave the user in the app as a guest, not staring at a spinner.
  Future<void> init() async {
    try {
      _session = SupabaseService.currentSession;

      _authSub = SupabaseService.auth.onAuthStateChange.listen(
        _onAuthStateChange,
        onError: (Object e) {
          debugPrint('AuthProvider: auth stream error: $e');
        },
      );
      unawaited(_listenForOAuthReturn());
    } catch (e) {
      debugPrint(
        'AuthProvider.init: auth unavailable, continuing as guest: $e',
      );
      _session = null;
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }

    if (_session != null) {
      unawaited(_refreshProfile());
    }
  }

  void _onAuthStateChange(AuthState state) {
    _session = state.session;
    if (_session != null) {
      unawaited(_refreshProfile());
    } else {
      _profile = null;
    }
    notifyListeners();
  }

  Future<void> _refreshProfile() async {
    final id = _session?.user.id;
    if (id == null) return;
    try {
      _profile = await ProfileService.fetchOwn(id);
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: profile fetch failed: $e');
    }
  }

  /// Sign in with a phone number **or** an email address, plus a password.
  /// Returns `null` on success, otherwise an [AppStrings] key.
  ///
  /// The website and the app share one Supabase project, so an account made
  /// on either side signs in on the other. Most existing accounts were
  /// created through Google and have no password at all, so a failed password
  /// attempt on an email identifier points the user at Google rather than
  /// just saying "wrong credentials".
  Future<String?> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final email = UzPhone.identifierToAuthEmail(identifier);
    if (email == null) return 'auth_error_identifier_invalid';

    try {
      final response = await SupabaseService.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _session = response.session;
      notifyListeners();
      unawaited(_refreshProfile());
      return null;
    } on AuthException catch (e) {
      final key = _mapAuthError(e);
      if (key == 'auth_error_invalid' && !UzPhone.isPhoneAccount(email)) {
        return 'auth_error_invalid_try_google';
      }
      return key;
    } catch (e) {
      debugPrint('AuthProvider.signInWithIdentifier: $e');
      return 'auth_error_offline';
    }
  }

  /// Emails a password-reset link. Only possible for real email accounts —
  /// phone accounts live under a synthetic `@pro.com` address that receives
  /// no mail, so those users are sent to the Telegram admin instead.
  ///
  /// Returns `null` on success, otherwise an [AppStrings] key.
  Future<String?> sendPasswordReset(String identifier) async {
    final email = UzPhone.identifierToAuthEmail(identifier);
    if (email == null) return 'auth_error_identifier_invalid';
    if (UzPhone.isPhoneAccount(email)) return 'auth_error_reset_phone_account';

    try {
      await SupabaseService.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      debugPrint('AuthProvider.sendPasswordReset: $e');
      return 'auth_error_offline';
    }
  }

  /// Creates a phone account and signs in with it.
  ///
  /// The account itself is created by the `phone-signup` Edge Function, not by
  /// `auth.signUp`: `@pro.com` is a real domain, so a client-side sign-up
  /// would send confirmation mail to a stranger's server. The function creates
  /// the user with `email_confirm: true` (no mail at all).
  ///
  /// No captcha is involved: the app sends no Turnstile token, and the
  /// function throttles token-less sign-ups per IP instead. Nothing is ever
  /// shown to the user.
  ///
  /// Returns `null` on success, otherwise an [AppStrings] key.
  Future<String?> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    final normalized = UzPhone.normalize(phone);
    if (normalized == null) return 'auth_error_phone_invalid';
    if (password.length < UzPhone.minPasswordLength) {
      return 'auth_error_weak_password';
    }

    try {
      final response = await SupabaseService.client.functions.invoke(
        'phone-signup',
        body: {'phone': normalized, 'password': password},
      );

      final data = response.data;
      final email = data is Map && data['email'] is String
          ? data['email'] as String
          : '$normalized@${UzPhone.emailDomain}';

      // The account exists now — sign in so the user doesn't retype anything.
      return signInWithIdentifier(identifier: email, password: password);
    } on FunctionException catch (e) {
      return _mapSignupError(e);
    } catch (e) {
      debugPrint('AuthProvider.signUpWithPhone: $e');
      return 'auth_error_offline';
    }
  }

  /// Google sign-in.
  ///
  /// FIRST the phone's own Google account sheet (Credential Manager): no
  /// browser and no return link — one tap on an account, and the ID token
  /// goes straight to Supabase. The browser round trip it replaces failed on
  /// real phones: Google answered, but the link back to the app never
  /// arrived (Supabase logs: /callback 302, no /token afterwards).
  ///
  /// THEN, only if that is not possible on this phone or not set up yet, the
  /// browser flow: Google's page in a Custom Tab, back through the deep link
  /// handled in [_handleOAuthReturn].
  Future<String?> signInWithGoogle() async {
    final native = await _signInWithGoogleNative();
    if (native != _useBrowser) return native;
    return _signInWithGoogleBrowser();
  }

  static const String _useBrowser = '_use_browser';
  static bool _googleReady = false;
  static String? _rawNonce;

  /// null on success or when the user closed the sheet; [_useBrowser] when
  /// the browser flow should take over.
  Future<String?> _signInWithGoogleNative() async {
    try {
      final google = GoogleSignIn.instance;
      if (!_googleReady) {
        // One nonce per app run (initialize may only be called once): Google
        // puts its hash in the token, Supabase checks it against this value.
        _rawNonce = _randomNonce();
        await google.initialize(
          serverClientId: SupabaseConfig.googleWebClientId,
          nonce: sha256.convert(utf8.encode(_rawNonce!)).toString(),
        );
        _googleReady = true;
      }
      if (!google.supportsAuthenticate()) return _useBrowser;

      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return _useBrowser;

      // The session then arrives through onAuthStateChange.
      await SupabaseService.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        nonce: _rawNonce,
      );
      return null;
    } on GoogleSignInException catch (e) {
      if (isUserCancel(e.code, e.description)) return null;
      // Not set up for this build (no Android OAuth client / SHA-1 in Google
      // Cloud), no Play services, or the sheet could not be shown. A missing
      // SHA-1 also comes back as "canceled" — but AFTER an account was
      // picked, with Google's own reason in the description. Say it on the
      // sign-in screen, then try the browser.
      _reportNativeGoogleError('${e.code.name}: ${e.description ?? ''}');
      return _useBrowser;
    } on AuthException catch (e) {
      _reportNativeGoogleError('Supabase: ${e.message}');
      return _useBrowser;
    } catch (e) {
      debugPrint('AuthProvider: native Google failed: $e');
      return _useBrowser;
    }
  }

  /// A real "the user closed the sheet", as opposed to Google refusing the
  /// app after an account was picked, which Credential Manager also reports
  /// as canceled ("[16] Account reauth failed", "[28444] Developer console is
  /// not set up correctly").
  @visibleForTesting
  static bool isUserCancel(
    GoogleSignInExceptionCode code,
    String? description,
  ) {
    if (code != GoogleSignInExceptionCode.canceled) return false;
    final text = (description ?? '').toLowerCase();
    return !RegExp(r'\[\d+\]').hasMatch(text) &&
        !text.contains('developer') &&
        !text.contains('reauth');
  }

  void _reportNativeGoogleError(String reason) {
    debugPrint('AuthProvider: native Google failed: $reason');
    _oauthError = reason.trim();
    notifyListeners();
  }

  static String _randomNonce() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => random.nextInt(256)));
  }

  Future<String?> _signInWithGoogleBrowser() async {
    try {
      final started = await SupabaseService.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.authRedirectUrl,
        authScreenLaunchMode: LaunchMode.inAppBrowserView,
      );
      return started ? null : 'auth_error_generic';
    } on AuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      debugPrint('AuthProvider.signInWithGoogle: $e');
      return 'auth_error_offline';
    }
  }

  /// Changes the signed-in user's password. `updateUser` always applies to the
  /// current session, so one user can never change another's password.
  /// Returns `null` on success, otherwise an [AppStrings] key.
  Future<String?> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = userEmail;
    if (email.isEmpty) return 'auth_error_generic';
    if (newPassword.length < UzPhone.minPasswordLength) {
      return 'auth_error_weak_password';
    }

    try {
      // Re-authenticate first so a forgotten unlocked phone can't be used to
      // take over the account.
      await SupabaseService.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } on AuthException catch (_) {
      return 'auth_error_current_password';
    } catch (e) {
      debugPrint('AuthProvider.updatePassword (reauth): $e');
      return 'auth_error_offline';
    }

    try {
      await SupabaseService.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return null;
    } on AuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      debugPrint('AuthProvider.updatePassword: $e');
      return 'auth_error_offline';
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.auth.signOut();
    } catch (e) {
      debugPrint('AuthProvider.signOut: $e');
    }
    // Next time the account sheet asks again instead of reusing this one.
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('AuthProvider.signOut (google): $e');
      }
    }
    // The cached cloud history belongs to the account that just left — on a
    // shared device the next person must not see it.
    try {
      await StorageService.clearCloudResultsCache();
    } catch (e) {
      debugPrint('AuthProvider.signOut (cache): $e');
    }
    _session = null;
    _profile = null;
    notifyListeners();
  }

  /// Permanently deletes the signed-in account and everything this device
  /// kept about it. Required by Google Play for any app that lets users
  /// register.
  ///
  /// The server decides *whose* account to delete from the access token, so
  /// this can only ever remove the caller's own. Returns `null` on success,
  /// otherwise an [AppStrings] key.
  Future<String?> deleteAccount() async {
    if (_session == null) return 'auth_error_generic';

    try {
      final response = await SupabaseService.client.functions.invoke(
        'delete-account',
        body: {'confirm': true},
      );
      final data = response.data;
      if (data is Map && data['ok'] != true) {
        debugPrint('AuthProvider.deleteAccount: ${data['error']}');
        return 'account_delete_failed';
      }
    } on FunctionException catch (e) {
      debugPrint('AuthProvider.deleteAccount (${e.status}): ${e.details}');
      return 'account_delete_failed';
    } catch (e) {
      debugPrint('AuthProvider.deleteAccount: $e');
      return 'auth_error_offline';
    }

    // The account is gone server-side; drop the local session and data too.
    try {
      await SupabaseService.auth.signOut();
    } catch (_) {
      /* Token is already invalid — nothing to revoke. */
    }
    await StorageService.clearAllUserData();

    _session = null;
    _profile = null;
    notifyListeners();
    return null;
  }

  /// Update the user's display name on the `profiles` table.
  Future<bool> updateFullName(String fullName) async {
    final id = userId;
    if (id == null) return false;
    try {
      final written = await ProfileService.updateFullName(id, fullName);
      if (!written) return false;
      _profile = UserProfile(
        id: id,
        username: _profile?.username,
        email: _profile?.email ?? userEmail,
        fullName: fullName,
        avatarUrl: _profile?.avatarUrl,
        tariffDays: _profile?.tariffDays ?? 0,
        tariffEndDate: _profile?.tariffEndDate,
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider.updateFullName: $e');
      return false;
    }
  }

  /// Maps the `phone-signup` error codes onto localized [AppStrings] keys.
  /// The function also returns a ready Uzbek `message`, but the app has all
  /// three languages, so the code wins.
  String _mapSignupError(FunctionException e) {
    final details = e.details;
    final code = details is Map && details['error'] is String
        ? details['error'] as String
        : '';

    switch (code) {
      case 'invalid_phone':
        return 'auth_error_phone_invalid';
      case 'weak_password':
        return 'auth_error_weak_password';
      case 'phone_taken':
        return 'auth_error_phone_taken';
      case 'rate_limited':
        return 'auth_error_rate_limit';
    }

    debugPrint('AuthProvider signup failed (${e.status}): $details');
    // Fall back to whatever the server said, if anything.
    if (details is Map && details['message'] is String) {
      return details['message'] as String;
    }
    return 'auth_error_generic';
  }

  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already exists') ||
        msg.contains('already been registered')) {
      return 'auth_error_email_taken';
    }
    if (msg.contains('password') && msg.contains('least')) {
      return 'auth_error_weak_password';
    }
    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        msg.contains('invalid email') ||
        msg.contains('invalid password')) {
      return 'auth_error_invalid';
    }
    if (msg.contains('email not confirmed')) {
      return 'auth_error_unconfirmed';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'auth_error_rate_limit';
    }
    if (msg.contains('network')) {
      return 'auth_error_network';
    }
    return 'auth_error_generic';
  }

  // ───────────────────────── Google return ─────────────────────────

  /// Google sign-in comes back as `uz.avtotestu.app://auth-callback?code=…`.
  /// The app handles that link itself (supabase_flutter's own handler is off,
  /// see SupabaseService): it swaps the code for a session, and when that
  /// fails it keeps the reason for the sign-in screen to show — the earlier
  /// "Google does nothing" reports had no error message to go on at all.
  StreamSubscription<Uri>? _linkSub;
  final Set<String> _handledCodes = {};

  String? _oauthError;
  bool _oauthInProgress = false;

  /// Why the last Google sign-in did not finish (server text), or null.
  String? get oauthError => _oauthError;

  /// The code from Google is being exchanged for a session.
  bool get oauthInProgress => _oauthInProgress;

  void clearOAuthError() {
    if (_oauthError == null) return;
    _oauthError = null;
    notifyListeners();
  }

  Future<void> _listenForOAuthReturn() async {
    try {
      final links = AppLinks();
      _linkSub = links.uriLinkStream.listen(
        _handleOAuthReturn,
        onError: (Object e) => debugPrint('AuthProvider: link stream: $e'),
      );
      // The app was closed while the user was on Google's page: the link is
      // the one it was started with.
      final initial = await links.getInitialLink();
      if (initial != null) await _handleOAuthReturn(initial);
    } catch (e) {
      debugPrint('AuthProvider: deep links unavailable: $e');
    }
  }

  /// The code or the error carried by a Google return link; null for any
  /// other link. Errors may come in the query or in the fragment.
  static ({String? code, String? error})? parseOAuthReturn(Uri uri) {
    final expected = Uri.parse(SupabaseConfig.authRedirectUrl);
    if (uri.scheme != expected.scheme || uri.host != expected.host) {
      return null;
    }
    final params = {
      ...uri.queryParameters,
      if (uri.fragment.isNotEmpty) ...Uri.splitQueryString(uri.fragment),
    };
    final error = params['error_description'] ?? params['error'];
    return (code: params['code'], error: error?.replaceAll('+', ' '));
  }

  Future<void> _handleOAuthReturn(Uri uri) async {
    final result = parseOAuthReturn(uri);
    if (result == null) return;
    if (result.error != null) {
      _oauthError = result.error;
      notifyListeners();
      return;
    }
    final code = result.code;
    if (code == null || !_handledCodes.add(code)) return;

    _oauthInProgress = true;
    _oauthError = null;
    notifyListeners();
    try {
      // The session then arrives through onAuthStateChange.
      await SupabaseService.auth
          .exchangeCodeForSession(code)
          .timeout(const Duration(seconds: 20));
    } on AuthException catch (e) {
      _oauthError = e.message;
    } on TimeoutException {
      _oauthError = 'timeout';
    } catch (e) {
      _oauthError = '$e';
    }
    _oauthInProgress = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _linkSub?.cancel();
    super.dispose();
  }
}
