import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

/// "Imtihonga tayyorgarlik" — the website's readiness score, read from the
/// same `get_user_readiness()` RPC (src/hooks/useReadiness.ts). The app never
/// computes the percent or the level itself: the formula lives on the server
/// only, so the site and the app can never disagree about a user's level.
@immutable
class Readiness {
  final int readinessPercent;
  final int accuracyPercent;
  final int coveragePercent;
  final int variantsPercent;
  final int masteryPercent;
  final int testsPercent;
  final int testsTotal;
  final int testsToday;
  final int testsTarget;
  final int questionsSeen;
  final int questionsTotal;
  final int questionsMastered;
  final int questionsToReview;
  final int variantsPassed;
  final int variantsAttempted;
  final int variantsTotal;
  final int levelIndex;
  final int levelMinPercent;
  final int? levelNextPercent;
  final int? percentToNext;
  final DateTime? examDate;
  final int? daysToExam;
  final int streakDays;

  /// False until the first test: the UI shows an invitation, never "0%".
  final bool hasData;

  const Readiness({
    required this.readinessPercent,
    required this.accuracyPercent,
    required this.coveragePercent,
    required this.variantsPercent,
    required this.masteryPercent,
    required this.testsPercent,
    required this.testsTotal,
    required this.testsToday,
    required this.testsTarget,
    required this.questionsSeen,
    required this.questionsTotal,
    required this.questionsMastered,
    required this.questionsToReview,
    required this.variantsPassed,
    required this.variantsAttempted,
    required this.variantsTotal,
    required this.levelIndex,
    required this.levelMinPercent,
    required this.levelNextPercent,
    required this.percentToNext,
    required this.examDate,
    required this.daysToExam,
    required this.streakDays,
    required this.hasData,
  });

  static int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  static int? _intOrNull(Object? v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));

  factory Readiness.fromRow(Map<String, dynamic> row) => Readiness(
    readinessPercent: _int(row['readiness_percent']).clamp(0, 100),
    accuracyPercent: _int(row['accuracy_percent']),
    coveragePercent: _int(row['coverage_percent']),
    variantsPercent: _int(row['variants_percent']),
    masteryPercent: _int(row['mastery_percent']),
    testsPercent: _int(row['tests_percent']),
    testsTotal: _int(row['tests_total']),
    testsToday: _int(row['tests_today']),
    testsTarget: _int(row['tests_target']),
    questionsSeen: _int(row['questions_seen']),
    questionsTotal: _int(row['questions_total']),
    questionsMastered: _int(row['questions_mastered']),
    questionsToReview: _int(row['questions_to_review']),
    variantsPassed: _int(row['variants_passed']),
    variantsAttempted: _int(row['variants_attempted']),
    variantsTotal: _int(row['variants_total']),
    levelIndex: _int(row['level_index']).clamp(1, readinessLevels.length),
    levelMinPercent: _int(row['level_min_percent']),
    levelNextPercent: _intOrNull(row['level_next_percent']),
    percentToNext: _intOrNull(row['percent_to_next']),
    examDate: row['exam_date'] == null
        ? null
        : DateTime.tryParse('${row['exam_date']}'),
    daysToExam: _intOrNull(row['days_to_exam']),
    streakDays: _int(row['streak_days']),
    hasData: row['has_data'] == true,
  );

  /// How far through the CURRENT level the user is, 0..1 — the strip's bar.
  /// Same arithmetic as the website's ReadinessStrip: the top level runs from
  /// its minimum to 100%.
  double get progressWithinLevel {
    final level = readinessLevels[levelIndex - 1];
    final span = (levelNextPercent ?? 100) - level.minPercent;
    if (span <= 0) return 1;
    return ((readinessPercent - level.minPercent) / span).clamp(0.0, 1.0);
  }
}

/// One step of the ladder. Must stay identical to the website's
/// `READINESS_LEVELS` (src/lib/readinessLevels.ts) — test/readiness_test.dart
/// pins the numbers.
@immutable
class ReadinessLevel {
  final int index;
  final int minPercent;
  final int maxPercent;
  const ReadinessLevel(this.index, this.minPercent, this.maxPercent);

  /// `readiness_level1` … `readiness_level6` in AppStrings.
  String get labelKey => 'readiness_level$index';
}

const List<ReadinessLevel> readinessLevels = [
  ReadinessLevel(1, 0, 29),
  ReadinessLevel(2, 30, 49),
  ReadinessLevel(3, 50, 69),
  ReadinessLevel(4, 70, 84),
  ReadinessLevel(5, 85, 94),
  ReadinessLevel(6, 95, 100),
];

/// Server access for [Readiness]. State lives in ReadinessProvider.
class ReadinessService {
  ReadinessService._();

  static const Duration _timeout = Duration(seconds: 10);
  static const String _cachePrefix = 'readiness_cache_';

  /// Bumped when something that changes the score was written (answers
  /// recorded, a result saved) — the provider refreshes on it.
  static final ValueNotifier<int> stale = ValueNotifier<int>(0);

  static void markStale() => stale.value++;

  /// Null when the server returned no row.
  static Future<Readiness?> fetch(String userId) async {
    final raw = await SupabaseService.client
        .rpc('get_user_readiness')
        .timeout(_timeout);
    final row = raw is List ? (raw.isEmpty ? null : raw.first) : raw;
    if (row is! Map) return null;
    final map = Map<String, dynamic>.from(row);
    unawaited(_remember(userId, map));
    return Readiness.fromRow(map);
  }

  /// The last answer for this user, from the device — shown at once on the
  /// next launch, and when the network is down.
  static Future<Readiness?> cached(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$userId');
      if (raw == null) return null;
      return Readiness.fromRow(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _remember(String userId, Map<String, dynamic> row) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$userId', jsonEncode(row));
    } catch (_) {
      // A cache is a convenience; failing to write one changes nothing.
    }
  }

  /// The optional exam date, in the existing `profiles.exam_date` column
  /// (the website's `saveExamDate`). Null clears it. Returns success.
  static Future<bool> saveExamDate(String userId, DateTime? date) async {
    final value = date == null
        ? null
        : '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'exam_date': value})
          .eq('id', userId)
          .timeout(_timeout);
      return true;
    } catch (e) {
      debugPrint('ReadinessService.saveExamDate: $e');
      return false;
    }
  }
}
