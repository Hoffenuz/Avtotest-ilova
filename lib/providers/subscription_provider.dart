import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/subscription_service.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

/// Holds the current user's PRO subscription state and exposes refresh hooks.
///
/// THREE STATES, NOT TWO. "No PRO" and "we have not asked yet" are different
/// answers, and treating them the same is what made a paying user get shown a
/// paywall: on the first frame after a gate mounted, `isPro` was false simply
/// because the RPC had not run, and the gate took that for a refusal. Callers
/// must check [isUnknown] before deciding anyone is unsubscribed.
class SubscriptionProvider extends ChangeNotifier {
  bool _loading = false;
  UserAccessState? _access;
  SubscriptionInfo? _info;
  String? _error;
  String? _lastCheckedUserId;
  Future<void>? _refreshFuture;
  DateTime? _lastRefreshAt;

  static const _softCacheTtl = Duration(seconds: 20);

  bool get loading => _loading;
  bool get isPro => _access?.isPremium ?? false;
  SubscriptionInfo? get info => _info;
  String? get error => _error;
  UserAccessState? get access => _access;

  /// Whether the current answer is settled.
  ///
  /// SIGNED OUT COUNTS AS SETTLED. There is no subscription without an
  /// account, so "nobody is signed in" is a complete answer, not a pending
  /// one. Deriving this from "have we got an access row" instead is what left
  /// a signed-out user tapping the explanation button watching a spinner
  /// forever: no row ever arrived, because nothing ever asks the server about
  /// a user who does not exist.
  bool _resolved = false;

  /// True only while a signed-in user is genuinely waiting on the server. A
  /// gate that sees this must wait; anything else must decide.
  bool get isUnknown => !_resolved;

  /// True when the answer is in and it is "no PRO" — the only state in which
  /// showing a paywall is correct.
  bool get isDeniedForSure => _resolved && !isPro;

  /// Whether the cached answer is recent enough to act on without re-asking.
  bool get isFresh =>
      _access != null &&
      _lastRefreshAt != null &&
      DateTime.now().difference(_lastRefreshAt!) < _softCacheTtl;

  /// Whether [bindAuth] has run at all. Without it the "same user, nothing to
  /// do" guard below fires on the FIRST bind of a signed-out session — null
  /// equals null — and the state is never settled, which is the spinner a
  /// guest saw instead of the PRO offer.
  bool _bound = false;

  void bindAuth(AuthProvider auth) {
    final newUserId = auth.userId;
    // A guest's auth notifications used to re-clear and re-notify on every
    // rebuild, waking every listening screen for nothing.
    if (_bound && newUserId == _lastCheckedUserId) return;
    _bound = true;
    _lastCheckedUserId = newUserId;

    if (newUserId == null) {
      _access = null;
      _info = null;
      _error = null;
      _loading = false;
      _lastRefreshAt = null;
      // Settled, not pending: a signed-out user has no subscription and never
      // will until they sign in, so every gate can answer immediately.
      _resolved = true;
      notifyListeners();
      return;
    }

    // A different user: whatever we knew belongs to the previous one.
    _resolved = false;
    refresh(force: false);
  }

  /// Fresh PRO check before opening a guarded test.
  Future<bool> ensureProAccess() async {
    await refresh(force: true);
    return isPro;
  }

  /// Re-checks access after a Payme checkout closes.
  ///
  /// Returning from the payment page does not mean the payment went through:
  /// Payme confirms it to our server out of band. The old schedule gave that
  /// ten seconds and then told the user "still checking", after which the
  /// twenty-second cache meant nothing asked again — so a payment that landed
  /// at second twelve stayed invisible until the app was restarted. That is
  /// the "I paid and had to reopen the app" report.
  ///
  /// Backs off instead of hammering: quick at first, because most
  /// confirmations are quick, then slower.
  ///
  /// Stops at about twenty seconds on purpose. This runs behind a dialog the
  /// user cannot dismiss, and holding someone there for the better part of a
  /// minute is worse than telling them it is being processed and letting
  /// [watchForActivation] finish the job in the background.
  static const List<Duration> _activationBackoff = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 4),
    Duration(seconds: 4),
    Duration(seconds: 4),
  ];

  Future<bool> pollForActivation() async {
    await refresh(force: true);
    if (isPro) return true;

    for (final wait in _activationBackoff) {
      await Future<void>.delayed(wait);
      await refresh(force: true);
      if (isPro) return true;
    }
    return isPro;
  }

  Timer? _activationWatch;

  /// Keeps looking for a payment that has not landed yet, quietly.
  ///
  /// The user has already been told it is being processed and has gone back to
  /// using the app; when the confirmation arrives, PRO should simply switch on
  /// under them. Without this the only way to find out was to restart.
  ///
  /// Gives up after [budget] — a payment that has not confirmed in three
  /// minutes needs support, not more polling.
  void watchForActivation({Duration budget = const Duration(minutes: 3)}) {
    if (isPro) return;
    _activationWatch?.cancel();

    final deadline = DateTime.now().add(budget);
    _activationWatch = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (isPro || DateTime.now().isAfter(deadline)) {
        timer.cancel();
        _activationWatch = null;
        return;
      }
      await refresh(force: true);
      if (isPro) {
        timer.cancel();
        _activationWatch = null;
      }
    });
  }

  void stopActivationWatch() {
    _activationWatch?.cancel();
    _activationWatch = null;
  }

  Future<void> refresh({bool force = false}) {
    final pending = _refreshFuture;

    // A forced caller must not be answered by a request that is already
    // running — that request may have started before whatever the caller is
    // reacting to (a finished payment, a re-login) and would report the old
    // answer. Queue a real one behind it instead.
    if (pending != null && !force) return pending;

    if (!force && isFresh) return Future.value();

    final next = pending == null
        ? _performRefresh()
        : pending.then((_) => _performRefresh());
    _refreshFuture = next;

    return next.whenComplete(() {
      if (identical(_refreshFuture, next)) _refreshFuture = null;
    });
  }

  /// Asks once if nothing is known yet, and does nothing otherwise. For
  /// screens that mount often and only need an answer to exist.
  Future<void> refreshIfUnknown() {
    if (!isUnknown) return Future.value();
    return refresh();
  }

  Future<void> _performRefresh() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      _access = null;
      _info = null;
      _loading = false;
      _error = null;
      _lastRefreshAt = null;
      _resolved = true; // see [_resolved]: signed out is an answer
      notifyListeners();
      return;
    }

    final showBlockingLoader = _access == null;
    if (showBlockingLoader) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final access = await SubscriptionService.fetchAccessState(userId);
      _access = access;
      _info = access.isPremium ? SubscriptionInfo.fromAccess(access) : null;
      _error = null;
      _resolved = true;
      _lastRefreshAt = DateTime.now();
    } catch (e) {
      // The previous answer is deliberately kept: a network blip must not
      // take PRO away from someone who has it (MOBILE-INTEGRATION.md §5).
      _error = 'subscription_fetch_error';
      debugPrint('SubscriptionProvider.refresh: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _access = null;
    _info = null;
    _error = null;
    _loading = false;
    _lastCheckedUserId = null;
    _lastRefreshAt = null;
    _refreshFuture = null;
    // A later bindAuth for a signed-in user must not be mistaken for "same
    // user, nothing to do".
    _bound = false;
    // Called on sign-out, which leaves a signed-out user — a settled state.
    _resolved = true;
    stopActivationWatch();
    notifyListeners();
  }

  @override
  void dispose() {
    stopActivationWatch();
    super.dispose();
  }
}
