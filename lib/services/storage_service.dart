import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

class StorageService {
  /// Serialises read-modify-write list updates. Without it two answers marked
  /// wrong (or two bookmarks) in quick succession can both read the same old
  /// list and the second write silently drops the first entry.
  static Future<void> _writeQueue = Future<void>.value();

  static Future<void> _serialize(Future<void> Function() action) {
    final next = _writeQueue.then((_) => action());
    _writeQueue = next.catchError((_) {});
    return next;
  }

  static const _legacyResultsKey = 'test_results';
  static const _practiceResultsKey = 'practice_test_results';
  static const _cloudResultsKey = 'cloud_test_results_cache';
  static const _nameKey = 'user_name';
  static const _langKey = 'app_language';
  static const _errorsKey = 'error_questions';
  static const _savedQuestionsKey = 'saved_questions';
  static const _questionStatsKey = 'question_stats';
  static const _authStatusKey = 'auth_status';
  static const _userEmailKey = 'user_email';

  static Future<void> savePracticeResult(TestResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final results = await getPracticeResults();
    results.insert(0, result);
    if (results.length > 100) results.removeLast();
    await prefs.setString(
      _practiceResultsKey,
      json.encode(results.map((r) => r.toJson()).toList()),
    );
  }

  static Future<void> clearPracticeResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_practiceResultsKey);
  }

  static Future<List<TestResult>> getPracticeResults() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_practiceResultsKey);
    if (data != null) {
      return _decodeResults(data);
    }

    final legacy = prefs.getString(_legacyResultsKey);
    if (legacy == null) return [];

    final practiceOnly = _decodeResults(
      legacy,
    ).where((r) => r.type == 'practice').toList();
    if (practiceOnly.isNotEmpty) {
      await prefs.setString(
        _practiceResultsKey,
        json.encode(practiceOnly.map((r) => r.toJson()).toList()),
      );
    }
    return practiceOnly;
  }

  static Future<void> saveCloudResultsCache(List<TestResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cloudResultsKey,
      json.encode(results.map((r) => r.toJson()).toList()),
    );
  }

  static Future<List<TestResult>> getCloudResultsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_cloudResultsKey);
    if (data == null) return [];
    return _decodeResults(data);
  }

  static Future<void> clearCloudResultsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cloudResultsKey);
  }

  static List<TestResult> _decodeResults(String data) {
    final List<dynamic> jsonList = json.decode(data) as List<dynamic>;
    return jsonList
        .map((j) => TestResult.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveName(String firstName, String lastName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, '$firstName|$lastName');
  }

  static Future<(String, String)> getName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey) ?? '|';
    final parts = name.split('|');
    return (parts.isNotEmpty ? parts[0] : '', parts.length > 1 ? parts[1] : '');
  }

  static Future<void> saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langKey) ?? 'uz_lat';
  }

  static Future<void> addErrorQuestion(String globalId) {
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final errors = await getErrorQuestions();
      if (!errors.contains(globalId)) {
        errors.add(globalId);
        await prefs.setStringList(_errorsKey, errors);
      }
    });
  }

  static Future<void> removeErrorQuestion(String globalId) {
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final errors = await getErrorQuestions();
      errors.remove(globalId);
      await prefs.setStringList(_errorsKey, errors);
    });
  }

  static Future<List<String>> getErrorQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_errorsKey) ?? [];
  }

  static Future<void> clearErrorQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_errorsKey);
  }

  /// Per-question tally: `globalId` -> (seen, correct).
  ///
  /// Held in memory and flushed on a timer. The first version wrote through on
  /// every answer, which meant parsing and re-serialising up to 1259 entries
  /// and committing them to disk between one question and the next — during a
  /// 100-question test, a hundred times. That is exactly the shape of work
  /// that turns into dropped frames and, on a slow phone, an ANR.
  static Map<String, List<int>>? _statsCache;
  static Timer? _statsFlushTimer;
  static bool _statsDirty = false;

  /// Long enough to collapse a burst of answers into one write, short enough
  /// that little is lost if the process is killed. [flushQuestionStats] covers
  /// the ordinary exits.
  static const Duration _statsFlushDelay = Duration(seconds: 3);

  static Future<Map<String, List<int>>> _loadStats() async {
    final cached = _statsCache;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_questionStatsKey) ?? const <String>[];
    final map = <String, List<int>>{};
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length != 3) continue;
      final seen = int.tryParse(parts[1]);
      final right = int.tryParse(parts[2]);
      if (seen == null || right == null || seen <= 0) continue;
      map[parts[0]] = [seen, right];
    }
    return _statsCache = map;
  }

  static Future<void> recordAnswer(String globalId, bool correct) async {
    final map = await _loadStats();
    final current = map[globalId] ?? [0, 0];
    map[globalId] = [current[0] + 1, current[1] + (correct ? 1 : 0)];
    _statsDirty = true;

    _statsFlushTimer?.cancel();
    _statsFlushTimer = Timer(_statsFlushDelay, flushQuestionStats);
  }

  /// Writes the tally out. Called on a timer, and worth calling directly when
  /// a test ends or the app goes to the background.
  static Future<void> flushQuestionStats() async {
    if (!_statsDirty) return;
    final map = _statsCache;
    if (map == null) return;

    _statsFlushTimer?.cancel();
    _statsFlushTimer = null;
    _statsDirty = false;

    await _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_questionStatsKey, [
        for (final e in map.entries) '${e.key}:${e.value[0]}:${e.value[1]}',
      ]);
    });
  }

  /// `globalId` -> (seen, correct).
  static Future<Map<String, (int, int)>> getQuestionStats() async {
    final map = await _loadStats();
    return {for (final e in map.entries) e.key: (e.value[0], e.value[1])};
  }

  static Future<void> clearQuestionStats() async {
    _statsFlushTimer?.cancel();
    _statsFlushTimer = null;
    _statsDirty = false;
    _statsCache = <String, List<int>>{};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_questionStatsKey);
  }

  static Future<void> addSavedQuestion(String globalId) {
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final saved = await getSavedQuestions();
      if (!saved.contains(globalId)) {
        saved.insert(0, globalId);
        await prefs.setStringList(_savedQuestionsKey, saved);
      }
    });
  }

  static Future<void> removeSavedQuestion(String globalId) {
    return _serialize(() async {
      final prefs = await SharedPreferences.getInstance();
      final saved = await getSavedQuestions();
      saved.remove(globalId);
      await prefs.setStringList(_savedQuestionsKey, saved);
    });
  }

  static Future<List<String>> getSavedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedQuestionsKey) ?? [];
  }

  static Future<void> clearSavedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedQuestionsKey);
  }

  static Future<bool> isQuestionSaved(String globalId) async {
    final saved = await getSavedQuestions();
    return saved.contains(globalId);
  }

  // ─── Auth Methods ───
  static Future<void> saveAuthStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authStatusKey, isLoggedIn);
  }

  static Future<bool> getAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authStatusKey) ?? false;
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Wipes everything this device stored about the person using it: results,
  /// mistakes, bookmarks and the cached cloud history. Used when an account is
  /// deleted, so nothing personal survives on the phone either.
  static Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _legacyResultsKey,
      _practiceResultsKey,
      _cloudResultsKey,
      _errorsKey,
      _savedQuestionsKey,
      _nameKey,
      _userEmailKey,
      _authStatusKey,
    ]) {
      await prefs.remove(key);
    }
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authStatusKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_nameKey);
  }
}
