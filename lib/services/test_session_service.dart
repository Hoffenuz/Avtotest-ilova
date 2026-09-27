import 'supabase_service.dart';

/// Outcome of [TestSessionService.startSession].
class TestSessionResult {
  final bool ok;
  final String? sessionId;
  final String? error; // 'network', 'no_premium_access', 'rpc_error'

  const TestSessionResult({required this.ok, this.sessionId, this.error});
}

/// Wraps the `start_test_session` RPC, which server-side re-verifies PRO
/// access (via `get_user_access_state`) at the moment a topic/variant test
/// starts — this is the actual mechanism that makes topic tests require a
/// live internet connection: a failed/timed-out RPC call means no session,
/// so the test never opens, no matter what the locally cached PRO flag says.
class TestSessionService {
  TestSessionService._();

  /// The `variant` value the backend reserves for a Real Exam attempt. The
  /// website uses the same number (`src/pages/RealImtihon.tsx`), so a run
  /// started in the app is indistinguishable from one started on the site.
  static const int realExamVariant = 97;

  /// The "difficult questions" pool. It is not one of the exam tickets, so it
  /// needs a number of its own: `deriveVariant` finds no digits in the key
  /// "difficult" and used to fall through to 1, filing every one of those
  /// sessions under exam ticket 1 and quietly corrupting that ticket's
  /// statistics.
  static const int difficultPoolVariant = 98;

  /// Derives the `variant` integer the real backend expects, since there is
  /// no separate category column: practice → 99, difficult pool → 98, real
  /// exam → 97, variant/topic → numeric prefix of [testKey] (e.g. "v37" → 37,
  /// "35a" → 35), clamped to 1-100.
  static int deriveVariant({required String type, String? testKey}) {
    if (type == 'practice') return 99;
    if (type == 'difficult') return difficultPoolVariant;
    if (type == 'exam') return realExamVariant;
    if (testKey == null) return 1;
    final match = RegExp(r'\d+').firstMatch(testKey);
    final n = match != null ? int.tryParse(match.group(0)!) ?? 1 : 1;
    return n.clamp(1, 100);
  }

  /// Starts a server-tracked test session. [isPremium] must be true for
  /// topic/variant tests. Free tests tolerate an RPC failure (offline-
  /// friendly) and proceed with a null session id; premium tests surface the
  /// failure so the caller can block the test from starting.
  static const Duration _timeout = Duration(seconds: 10);

  static Future<TestSessionResult> startSession({
    required int variant,
    required String questionSource,
    required bool isPremium,
  }) async {
    try {
      // Bounded: on a bad connection the call used to hang with nothing on
      // screen. A timeout lands in the catch below like any network error.
      final raw = await SupabaseService.client
          .rpc(
            'start_test_session',
            params: {
              'p_variant': variant,
              'p_question_source': questionSource,
              'p_is_premium': isPremium,
            },
          )
          .timeout(_timeout);

      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final ok = map['ok'] as bool? ?? false;

      if (!ok) {
        if (!isPremium) {
          return const TestSessionResult(ok: true, sessionId: null);
        }
        return TestSessionResult(
          ok: false,
          error: (map['error'] as String?) ?? 'rpc_error',
        );
      }

      return TestSessionResult(
        ok: true,
        sessionId: map['session_id'] as String?,
      );
    } catch (_) {
      if (!isPremium) {
        return const TestSessionResult(ok: true, sessionId: null);
      }
      return const TestSessionResult(ok: false, error: 'network');
    }
  }
}
