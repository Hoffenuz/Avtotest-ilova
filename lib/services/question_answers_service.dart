import 'package:flutter/foundation.dart';

import 'readiness_service.dart';
import 'supabase_service.dart';

/// Writes a finished test's answers to `user_question_state` through the
/// existing `record_question_answers` RPC — exactly what the website does at
/// the end of every test (src/lib/questionState.ts). Without it, tests taken
/// in the app never reached "coverage", "mastery" or the list of questions
/// to review, and the readiness level lagged behind the website's.
class QuestionAnswersService {
  QuestionAnswersService._();

  /// The RPC accepts at most this many per call (one test never has more).
  static const int _maxAnswers = 100;

  /// [answers] — only the questions the user actually answered, as
  /// (globalId, isCorrect). Signed-out users and failures are silently
  /// skipped: this must never get in the way of finishing a test.
  static Future<void> record(List<(String, bool)> answers) async {
    if (SupabaseService.currentUserId == null) return;
    final payload = [
      for (final (id, correct) in answers)
        if (id.isNotEmpty) {'global_id': id, 'is_correct': correct},
    ].take(_maxAnswers).toList();
    if (payload.isEmpty) return;

    try {
      await SupabaseService.client
          .rpc('record_question_answers', params: {'p_answers': payload})
          .timeout(const Duration(seconds: 15));
      ReadinessService.markStale();
    } catch (e) {
      debugPrint('QuestionAnswersService.record: $e');
    }
  }
}
