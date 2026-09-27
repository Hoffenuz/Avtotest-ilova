import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/readiness_service.dart';
import '../services/test_results_service.dart';

/// The one source of the readiness score for every screen — the app's
/// counterpart of the website's `useReadiness` (a single snapshot, one
/// request in flight at a time, shared by the home strip and the full card).
///
/// Never blocks start-up: the last answer for this user is shown from the
/// device at once, the server is asked in the background, and a failure keeps
/// what is already on screen.
class ReadinessProvider extends ChangeNotifier {
  ReadinessProvider() {
    TestResultsService.revision.addListener(_onScoreChanged);
    ReadinessService.stale.addListener(_onScoreChanged);
  }

  String? _userId;
  Readiness? _data;

  /// An answer (or a failure) has arrived for the current user.
  bool _settled = false;
  Future<void>? _inflight;
  Timer? _debounce;

  /// Signed in — the only case the score exists for.
  bool get active => _userId != null;

  Readiness? get data => _data;

  /// Nothing to show yet: the skeleton.
  bool get loading => active && _data == null && !_settled;

  /// Asked, and nothing came back (offline, no row): a neutral link.
  bool get unavailable => active && _data == null && _settled;

  /// Called whenever the signed-in account may have changed.
  void attach(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _data = null;
    _settled = false;
    _debounce?.cancel();
    notifyListeners();
    if (userId == null) return;

    ReadinessService.cached(userId).then((cached) {
      if (_userId == userId && _data == null && cached != null) {
        _data = cached;
        notifyListeners();
      }
    });
    refresh();
  }

  /// Fetches now; joins a request already on its way.
  Future<void> refresh() {
    final userId = _userId;
    if (userId == null) return Future.value();
    return _inflight ??= _fetch(userId).whenComplete(() => _inflight = null);
  }

  Future<void> _fetch(String userId) async {
    try {
      final fresh = await ReadinessService.fetch(userId);
      if (_userId != userId) return;
      if (fresh != null) _data = fresh;
    } catch (e) {
      debugPrint('ReadinessProvider: $e');
    }
    if (_userId != userId) return;
    _settled = true;
    notifyListeners();
  }

  /// A result was saved or answers were recorded: ask again shortly, once,
  /// after both writes of a finished test have had time to land.
  void _onScoreChanged() {
    if (!active) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), refresh);
  }

  Future<bool> saveExamDate(DateTime? date) async {
    final userId = _userId;
    if (userId == null) return false;
    final ok = await ReadinessService.saveExamDate(userId, date);
    if (ok) await refresh();
    return ok;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    TestResultsService.revision.removeListener(_onScoreChanged);
    ReadinessService.stale.removeListener(_onScoreChanged);
    super.dispose();
  }
}
