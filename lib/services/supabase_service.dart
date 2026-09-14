import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Thin wrapper around the Supabase client.
///
/// Centralises initialization and exposes a single, easy-to-mock entry point
/// (`SupabaseService.client`) for the rest of the app.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  /// Initialize the global Supabase client.
  ///
  /// Safe to call multiple times — only the first call has effect.
  /// Sessions are persisted via the default `SharedPreferencesLocalStorage`,
  /// so a logged-in user remains logged in after a cold start.
  static Future<void> init() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      debug: false,
    );

    _initialized = true;
  }

  /// Whether [init] has completed. `main()` treats a failed init as "the user
  /// starts signed out" rather than a fatal error, so this can legitimately be
  /// false while the app runs normally offline.
  static bool get isInitialized => _initialized;

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  // The session accessors answer "is anyone signed in?", which has a correct
  // answer even when the client was never created: no. Reaching through to
  // `Supabase.instance` in that state throws instead, and these are read from
  // places that cannot do anything useful with an exception — finishing a
  // test, for one, which would lose the result to an unhandled async error.
  static Session? get currentSession =>
      _initialized ? auth.currentSession : null;

  static User? get currentUser => _initialized ? auth.currentUser : null;

  static String? get currentUserId => currentUser?.id;
}
