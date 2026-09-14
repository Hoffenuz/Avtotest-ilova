import 'dart:async';

import 'package:flutter/foundation.dart';
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

  /// Google sign-in. The browser returns to the app through the deep link
  /// registered in AndroidManifest.xml; `supabase_flutter` picks the session
  /// up from there and [_onAuthStateChange] fires.
  Future<String?> signInWithGoogle() async {
    try {
      final started = await SupabaseService.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.authRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
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

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
