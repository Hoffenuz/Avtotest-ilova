import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/question.dart';
import 'question_service.dart';
import 'storage_service.dart';

/// How one topic is going.
class TopicStat {
  final Topic topic;

  /// Questions from this topic the user has answered at least once.
  final int answered;

  /// How many of this topic's questions exist at all.
  final int total;

  /// Attempts, and how many of them were right. One question answered three
  /// times counts three times — improving on a question you kept missing
  /// should move the number.
  final int attempts;
  final int correct;

  const TopicStat({
    required this.topic,
    required this.answered,
    required this.total,
    required this.attempts,
    required this.correct,
  });

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  int get accuracyPercent => (accuracy * 100).round();

  /// Share of the topic that has been touched at all.
  double get coverage => total == 0 ? 0 : answered / total;

  bool get hasData => attempts > 0;
}

/// Turns the per-question tally into "you get 62% of intersection questions
/// right" — the thing a results screen full of "17/20" cannot tell anyone.
///
/// Everything it needs is already on the device: [StorageService] records each
/// answer, and the themed files map questions to topics. No network, no new
/// table, no extra column.
class TopicStatsService {
  TopicStatsService._();

  /// Topic id -> its question ids. Cached: the id lists are small, but there
  /// are 33 of them and this screen is opened repeatedly.
  static Map<String, Set<String>>? _membership;

  static Future<Map<String, Set<String>>> _loadMembership() async {
    final cached = _membership;
    if (cached != null) return cached;

    final out = <String, Set<String>>{};
    for (final topic in QuestionService.getTopics()) {
      // "Barcha savollar" is every question at once; as a row in a per-topic
      // breakdown it would just restate the overall average.
      if (topic.isAllQuestions) continue;
      out[topic.id] = await _idsOf(topic.filename);
    }
    _membership = out;
    return out;
  }

  /// Reads a themed file's ids without building [Question] objects — the
  /// files are plain id lists, and this only needs the ids.
  static Future<Set<String>> _idsOf(String filename) async {
    try {
      final raw = await rootBundle.loadString(
        'assets/tests-json/themes/$filename',
      );
      final decoded = json.decode(raw);
      if (decoded is! List) return const {};

      // Normally a list of ids. A file left in the expanded form still works.
      return {
        for (final entry in decoded)
          if (entry is String)
            entry
          else if (entry is Map && entry['task_info'] is Map)
            (entry['task_info'] as Map)['global_id'] as String,
      };
    } catch (_) {
      return const {};
    }
  }

  /// One row per topic, worst accuracy first — the list is there to answer
  /// "what should I revise", so the answer belongs at the top. Topics with no
  /// attempts sink to the bottom rather than showing a misleading 0%.
  static Future<List<TopicStat>> compute() async {
    final stats = await StorageService.getQuestionStats();
    final membership = await _loadMembership();

    final rows = <TopicStat>[];
    for (final topic in QuestionService.getTopics()) {
      final ids = membership[topic.id];
      if (ids == null || ids.isEmpty) continue;

      var answered = 0;
      var attempts = 0;
      var correct = 0;
      for (final id in ids) {
        final entry = stats[id];
        if (entry == null) continue;
        answered++;
        attempts += entry.$1;
        correct += entry.$2;
      }

      rows.add(
        TopicStat(
          topic: topic,
          answered: answered,
          total: ids.length,
          attempts: attempts,
          correct: correct,
        ),
      );
    }

    rows.sort((a, b) {
      if (a.hasData != b.hasData) return a.hasData ? -1 : 1;
      return a.accuracy.compareTo(b.accuracy);
    });
    return rows;
  }

  /// Overall accuracy across every recorded answer.
  static Future<(int attempts, int correct)> overall() async {
    final stats = await StorageService.getQuestionStats();
    var attempts = 0;
    var correct = 0;
    for (final entry in stats.values) {
      attempts += entry.$1;
      correct += entry.$2;
    }
    return (attempts, correct);
  }
}
