import 'dart:math';

import '../models/question.dart';
import 'question_service.dart';

/// Builds a Pro-gated test pool weighted toward historically harder question
/// categories: intersections/right-of-way, sign/term meanings, first aid,
/// and long/wordy questions (a runtime heuristic — there's no dedicated
/// "long question" tag in the source data).
class DifficultQuestionsService {
  DifficultQuestionsService._();

  static const List<String> intersectionTopicIds = ['20', '33', '34'];
  static const List<String> signTopicIds = ['3', '4', '5', '6', '7', '8'];
  static const List<String> firstAidTopicIds = ['30'];

  static const int defaultTestLength = 20;

  /// Target share of the test each bucket should contribute, before dedup
  /// and shortfall backfill. Tunable.
  static const Map<String, double> _bucketWeights = {
    'intersections': 0.30,
    'signs': 0.25,
    'firstAid': 0.20,
    'long': 0.25,
  };

  static Future<List<Question>> buildPool({
    int length = defaultTestLength,
  }) async {
    final topics = QuestionService.getTopics();

    Future<List<Question>> loadByTopicIds(List<String> ids) async {
      final filenames = topics
          .where((t) => ids.contains(t.id) && !t.isAllQuestions)
          .map((t) => t.filename);
      final lists = await Future.wait(
        filenames.map(QuestionService.loadTopicQuestions),
      );
      return lists.expand((l) => l).toList();
    }

    final intersections = await loadByTopicIds(intersectionTopicIds);
    final signs = await loadByTopicIds(signTopicIds);
    final firstAid = await loadByTopicIds(firstAidTopicIds);
    final long = await _loadLongQuestions();

    final random = Random();
    final buckets = <String, List<Question>>{
      'intersections': List.of(intersections)..shuffle(random),
      'signs': List.of(signs)..shuffle(random),
      'firstAid': List.of(firstAid)..shuffle(random),
      'long': long..shuffle(random),
    };

    final chosen = <String, Question>{};
    final order = <String>[];

    void takeFrom(String key, int count) {
      final list = buckets[key]!;
      var taken = 0;
      for (final q in list) {
        if (taken >= count) break;
        if (chosen.containsKey(q.globalId)) continue;
        chosen[q.globalId] = q;
        order.add(q.globalId);
        taken++;
      }
    }

    for (final entry in _bucketWeights.entries) {
      takeFrom(entry.key, (length * entry.value).round());
    }

    // Backfill any shortfall (e.g. first-aid alone can't cover 20% of a
    // 20-question test) from the union of everything not yet chosen.
    if (chosen.length < length) {
      final remaining = <String, Question>{};
      for (final list in buckets.values) {
        for (final q in list) {
          if (!chosen.containsKey(q.globalId)) {
            remaining[q.globalId] = q;
          }
        }
      }
      final remainingList = remaining.values.toList()..shuffle(random);
      for (final q in remainingList) {
        if (chosen.length >= length) break;
        chosen[q.globalId] = q;
        order.add(q.globalId);
      }
    }

    final result = order.map((id) => chosen[id]!).toList()..shuffle(random);
    return result;
  }

  /// Questions whose (uz_lat) text is at/above the 85th percentile word
  /// count of the full bank — computed at call time so it self-calibrates
  /// if the question bank changes.
  static Future<List<Question>> _loadLongQuestions() async {
    final all = await QuestionService.loadAllQuestions();
    if (all.isEmpty) return [];

    final counts = all.map(_wordCount).toList()..sort();
    final thresholdIndex = (counts.length * 0.85).floor().clamp(
      0,
      counts.length - 1,
    );
    final threshold = counts[thresholdIndex];
    if (threshold <= 0) return [];

    return all.where((q) => _wordCount(q) >= threshold).toList();
  }

  static int _wordCount(Question q) {
    var text = q.texts['uz_lat'] ?? '';
    if (text.trim().isEmpty && q.texts.isNotEmpty) {
      text = q.texts.values.first;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }
}
