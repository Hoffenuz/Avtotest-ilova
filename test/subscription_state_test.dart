import 'package:avtotest_app/providers/auth_provider.dart';
import 'package:avtotest_app/providers/subscription_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bug these exist for: a paying user being shown "buy PRO".
///
/// It was never a wrong answer from the server — it was the app treating "the
/// server has not answered yet" as "the answer is no". Supabase is not
/// initialized in tests, so `_performRefresh` takes its no-user path; that is
/// enough to pin down the state machine every gate reads.
void main() {
  test('a fresh provider knows nothing — it does not claim "no PRO"', () {
    final sub = SubscriptionProvider();

    expect(sub.isUnknown, isTrue);
    expect(sub.isPro, isFalse);
    expect(
      sub.isDeniedForSure,
      isFalse,
      reason: 'nothing has been asked yet, so nothing has been refused',
    );
  });

  group('signed out is an answer, not a wait', () {
    // The bug: a signed-out user tapping the explanation button watched a
    // spinner forever. `isUnknown` was derived from "do we hold an access
    // row", and no row ever arrives for someone with no account — so every
    // gate that waits on it waited for good.
    test('binding a signed-out session settles the state', () {
      final sub = SubscriptionProvider()..bindAuth(AuthProvider());

      expect(sub.isUnknown, isFalse, reason: 'nothing left to wait for');
      expect(sub.isPro, isFalse);
      expect(
        sub.isDeniedForSure,
        isTrue,
        reason: 'a guest must get the PRO offer, not a spinner',
      );
    });

    test('a refresh with no user settles rather than hanging', () async {
      final sub = SubscriptionProvider();
      await sub.refresh(force: true);

      expect(sub.isUnknown, isFalse);
      expect(sub.isDeniedForSure, isTrue);
      expect(sub.loading, isFalse);
    });

    test('signing out settles too', () {
      final sub = SubscriptionProvider()..clear();
      expect(sub.isUnknown, isFalse);
      expect(sub.isDeniedForSure, isTrue);
    });
  });

  group('waiting for a payment to confirm', () {
    test('the watch stops on its own when the budget runs out', () async {
      final sub = SubscriptionProvider();
      sub.watchForActivation(budget: const Duration(milliseconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 120));
      // Nothing to assert beyond "it did not throw and left no timer": a
      // leaked periodic timer fails the test binding at teardown.
      sub.stopActivationWatch();
      expect(sub.isPro, isFalse);
    });

    test('stopping an unstarted watch is harmless', () {
      SubscriptionProvider().stopActivationWatch();
    });
  });

  test('unknown and denied are mutually exclusive', () {
    final sub = SubscriptionProvider();
    expect(sub.isUnknown && sub.isDeniedForSure, isFalse);
  });

  test('an unresolved provider is never treated as fresh', () {
    final sub = SubscriptionProvider();
    expect(
      sub.isFresh,
      isFalse,
      reason:
          'the guarded launcher skips its access RPC on `isFresh`; '
          'saying yes here would skip the only check there is',
    );
  });

  test('clear() drops the subscription without inventing one', () {
    final sub = SubscriptionProvider()..clear();

    expect(sub.isPro, isFalse);
    expect(sub.info, isNull);
    expect(sub.access, isNull);
  });

  test('refreshIfUnknown is a no-op once something is known', () async {
    final sub = SubscriptionProvider();
    // With no signed-in user the refresh resolves immediately and SETTLES:
    // "no account, so no subscription" is a complete answer.
    await sub.refreshIfUnknown();
    expect(sub.isUnknown, isFalse);
    expect(sub.isPro, isFalse);
  });

  test('concurrent refreshes do not pile up', () async {
    final sub = SubscriptionProvider();
    await Future.wait([sub.refresh(), sub.refresh(), sub.refresh(force: true)]);
    expect(sub.loading, isFalse);
  });

  test('a guest never ends up marked premium', () async {
    final sub = SubscriptionProvider();
    expect(await sub.ensureProAccess(), isFalse);
    expect(sub.isPro, isFalse);
  });
}
