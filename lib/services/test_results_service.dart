import 'package:flutter/foundation.dart';

import '../models/question.dart';
import 'app_strings.dart';
import 'question_service.dart';
import 'storage_service.dart';
import 'supabase_service.dart';
import 'test_session_service.dart';

class TestResultsService {
  TestResultsService._();

  /// Bumped whenever the stored results change. Screens that cache a results
  /// list (home, profile) listen to it so finishing a test updates their
  /// statistics immediately instead of after a manual pull-to-refresh.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void _notifyChanged() => revision.value++;

  /// Saves a finished test's result.
  ///
  /// Practice results stay local-only (matches the website: only logged-in
  /// topic/variant attempts are persisted server-side). Topic/variant results
  /// are saved via the `verify_and_save_test_result` RPC, which re-validates
  /// [sessionId] server-side (must be un-expired, belong to the caller, and
  /// — for PRO sessions — the caller's access must still be active at save
  /// time) before inserting into `test_results`. [sessionId] should be the
  /// id returned by [TestSessionService.startSession] when the test began;
  /// it will be null if that session start failed for a free test.
  static Future<void> save(TestResult result, {String? sessionId}) async {
    if (result.type == 'practice') {
      await StorageService.savePracticeResult(result);
      _notifyChanged();
      return;
    }

    if (result.type != 'topic' &&
        result.type != 'variant' &&
        result.type != 'exam') {
      return;
    }

    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final variant = TestSessionService.deriveVariant(
      type: result.type,
      testKey: result.testKey,
    );

    try {
      final raw = await SupabaseService.client.rpc(
        'verify_and_save_test_result',
        params: {
          'p_session_id': sessionId,
          'p_variant': variant,
          'p_correct_answers': result.correctAnswers,
          'p_total_questions': result.totalQuestions,
          'p_time_taken_seconds': result.timeSpentSeconds.clamp(0, 3659),
        },
      ).timeout(const Duration(seconds: 15));

      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      if (map['ok'] != true) return;

      final saved = TestResult(
        id: map['result_id'] as String?,
        type: result.type,
        testKey: result.testKey,
        label: result.label,
        totalQuestions: result.totalQuestions,
        correctAnswers: result.correctAnswers,
        timeSpentSeconds: result.timeSpentSeconds,
        date: result.date,
        isCompleted: result.isCompleted,
      );

      final cached = await StorageService.getCloudResultsCache();
      cached.insert(0, saved);
      if (cached.length > 100) cached.removeLast();
      await StorageService.saveCloudResultsCache(cached);
      _notifyChanged();
    } catch (_) {
      // Keep local cache untouched on network errors.
    }
  }

  static Future<List<TestResult>> getPracticeResults() =>
      StorageService.getPracticeResults();

  static Future<List<TestResult>> getCloudResults() =>
      StorageService.getCloudResultsCache();

  static Future<List<TestResult>> refreshCloud() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      await StorageService.clearCloudResultsCache();
      return [];
    }

    final rows = await SupabaseService.client
        .from('test_results')
        .select(
          'id, variant, correct_answers, total_questions, time_taken_seconds, question_source, created_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100)
        .timeout(const Duration(seconds: 15));

    final results = (rows as List<dynamic>)
        .map((row) => _fromSupabaseRow(row as Map<String, dynamic>))
        .toList();

    await StorageService.saveCloudResultsCache(results);
    return results;
  }

  static Future<void> clearPracticeResults() async {
    await StorageService.clearPracticeResults();
    _notifyChanged();
  }

  /// A human name for a finished test.
  ///
  /// `test_results` is shared with the website, and the two write
  /// `question_source` in DIFFERENT shapes for the same test:
  ///
  /// | test          | website          | this app              |
  /// |---------------|------------------|-----------------------|
  /// | exam ticket   | `v27.json`       | `v27`                 |
  /// | topic         | `t31.json`       | `31`                  |
  /// | topic (named) | `t34.json`       | `34tengaxamiyatli`    |
  /// | real exam     | `barcha-ru.json` | `barcha-ru.json`      |
  /// | mistakes      | `mistakes`       | (local only)          |
  ///
  /// Only the app's own shapes were ever decoded, so every result the user
  /// had created on avtotestu.uz showed up in their history as the raw string
  /// — `v27.json` sitting in the list like a leaked filename. Nothing here may
  /// return a file name: a name that cannot be resolved becomes a plain
  /// "Test", which tells the user no less than `t35a.json` did.
  static String resolveLabel({
    required String type,
    required String testKey,
    required String fallback,
    required String lang,
  }) {
    // The exam's source is a data-file name in both clients.
    if (type == 'exam') return AppStrings.get('real_exam', lang);

    final key = _stripJson(testKey);

    if (key == 'mistakes') return AppStrings.get('my_errors', lang);

    if (type == 'variant' || RegExp(r'^v\d+$').hasMatch(key)) {
      final match = RegExp(r'^v(\d+)$').firstMatch(key);
      final num = match != null ? int.tryParse(match.group(1)!) : null;
      if (num != null) return '${AppStrings.get('variant', lang)} $num';
    }

    final topic = _findTopic(key);
    if (topic != null) return topic.getName(lang);

    // Never leak a file name into the UI.
    if (fallback.isNotEmpty && !_looksLikeSource(fallback)) return fallback;
    return AppStrings.get('test_result_generic', lang);
  }

  static String _stripJson(String value) =>
      value.endsWith('.json') ? value.substring(0, value.length - 5) : value;

  /// Matches a topic by id or by its bundled file name, accepting the
  /// website's `t`-prefixed form (`t35a` → topic `35a`).
  static Topic? _findTopic(String key) {
    if (key.isEmpty) return null;

    final candidates = <String>{
      key,
      if (key.length > 1 && key.startsWith('t')) key.substring(1),
    };
    for (final topic in QuestionService.getTopics()) {
      // "Barcha savollar" has no file of its own, so its file key is the empty
      // string — without this guard every unrecognisable source matched it.
      final fileKey = _stripJson(topic.filename);
      if (candidates.contains(topic.id) ||
          (fileKey.isNotEmpty && candidates.contains(fileKey))) {
        return topic;
      }
    }
    return null;
  }

  /// True for anything that reads like a data source rather than a title.
  static bool _looksLikeSource(String value) =>
      value.endsWith('.json') || RegExp(r'^[a-z0-9_-]+$').hasMatch(value);

  /// The real `test_results` table has no `category`/`test_key` columns —
  /// only `variant` (a lossy int) and `question_source` (whatever string the
  /// client passed to `start_test_session`). Both are needed: `variant` is the
  /// only reliable marker of a Real Exam, `question_source` is the only thing
  /// that distinguishes one topic from another.
  static TestResult _fromSupabaseRow(Map<String, dynamic> row) {
    final questionSource = row['question_source'] as String?;
    final variant = (row['variant'] as num?)?.toInt() ?? 0;
    final createdAt = DateTime.parse(row['created_at'] as String);

    final testKey = questionSource ?? '$variant';
    final type = _classify(testKey, variant);

    return TestResult(
      id: row['id'] as String?,
      type: type,
      testKey: testKey,
      // `label` is only the cached fallback; every screen calls
      // `displayLabel(lang)`, which re-resolves in the user's language.
      label: resolveLabel(
        type: type,
        testKey: testKey,
        fallback: '',
        lang: 'uz_lat',
      ),
      totalQuestions: row['total_questions'] as int,
      correctAnswers: row['correct_answers'] as int,
      timeSpentSeconds: row['time_taken_seconds'] as int,
      date: createdAt,
      isCompleted: true,
    );
  }

  /// `variant` first: a Real Exam's `question_source` is a data-file name that
  /// an ordinary test could also carry, so the reserved number decides.
  static String _classify(String testKey, int variant) {
    if (variant == TestSessionService.realExamVariant) return 'exam';
    final key = _stripJson(testKey);
    if (RegExp(r'^v\d+$').hasMatch(key)) return 'variant';
    return 'topic';
  }
}

extension TestResultDisplay on TestResult {
  String displayLabel(String lang) {
    if (type == 'exam') {
      return TestResultsService.resolveLabel(
        type: type,
        testKey: testKey ?? '',
        fallback: '',
        lang: lang,
      );
    }
    if (testKey != null && (type == 'topic' || type == 'variant')) {
      return TestResultsService.resolveLabel(
        type: type,
        testKey: testKey!,
        fallback: label,
        lang: lang,
      );
    }
    return label;
  }
}
