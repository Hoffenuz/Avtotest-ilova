import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_strings.dart';
import '../services/connectivity_service.dart';
import '../services/test_session_service.dart';

/// Verifies PRO in the database, starts a server-tracked test session (which
/// re-verifies access again, server-side, at session-start time), then runs
/// [onGranted] with the resulting session id. A session-start failure means
/// either no PRO access or no internet connection — both must hold for a
/// topic/variant test to begin, matching the requirement that these sections
/// require an active connection, not just a locally cached PRO flag.
/// True while a guarded launch is in flight — the checks below can take a
/// few seconds, and without this a second tap started a second server
/// session for the same test.
bool _launchInProgress = false;

Future<void> launchGuardedTest(
  BuildContext context, {
  required String testType, // 'topic' | 'variant'
  required String testKey,
  required void Function(String? sessionId) onGranted,

  /// Called when access was refused because the user has no active PRO — not
  /// when the check merely failed (offline, server error), which stays a
  /// message. Lets the caller offer the upgrade instead of leaving a snackbar
  /// as the only answer to "why can't I open this?".
  VoidCallback? onDenied,
}) async {
  if (_launchInProgress) return;
  _launchInProgress = true;

  final sub = context.read<SubscriptionProvider>();
  final lang = context.read<LanguageProvider>().lang;
  final messenger = ScaffoldMessenger.of(context);

  void showMessage(String key) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppStrings.get(key, lang)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // The connectivity probe plus two RPCs can take several seconds; without a
  // visible indicator the app looked frozen after tapping a topic. The route
  // is pushed (and later removed) by reference rather than popped, so it can
  // never take another route with it whatever else happens to the stack.
  final navigator = Navigator.of(context, rootNavigator: true);
  final loaderRoute = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const _LaunchLoader(),
  );
  navigator.push(loaderRoute);
  var loaderClosed = false;

  void closeLoader() {
    if (loaderClosed) return;
    loaderClosed = true;
    navigator.removeRoute(loaderRoute);
  }

  try {
    // Fast local check first: topic/variant tests require connectivity no
    // matter what, so fail fast with a clear message rather than waiting on
    // an RPC timeout when the device is obviously offline.
    final online = await ConnectivityService.isOnline();
    if (!context.mounted) return;
    if (!online) {
      closeLoader();
      showMessage('connectivity_required_test');
      return;
    }

    // The forced access RPC is skipped when a fresh "yes" is already in hand.
    // It is not the thing that protects anything: `start_test_session` below
    // re-verifies access server-side, which is the check that actually
    // matters. Asking twice cost a full round trip on every single tap, and
    // with the loader up that is exactly what a subscriber experienced as the
    // app hanging before each topic.
    final ok = (sub.isPro && sub.isFresh) || await sub.ensureProAccess();
    if (!context.mounted) return;

    if (!ok) {
      closeLoader();
      // A failed check is not the same as a refusal: only an answered "no"
      // should push the paywall at someone.
      if (sub.error != null) {
        showMessage('subscription_fetch_error');
      } else if (onDenied != null) {
        onDenied();
      } else {
        showMessage('requires_pro');
      }
      return;
    }

    final variant = TestSessionService.deriveVariant(
      type: testType,
      testKey: testKey,
    );
    final session = await TestSessionService.startSession(
      variant: variant,
      questionSource: testKey,
      isPremium: true,
    );
    if (!context.mounted) return;

    closeLoader();

    if (!session.ok) {
      if (session.error == 'network') {
        showMessage('connectivity_required_test');
      } else if (onDenied != null) {
        onDenied();
      } else {
        showMessage('requires_pro');
      }
      return;
    }

    onGranted(session.sessionId);
  } finally {
    closeLoader();
    _launchInProgress = false;
  }
}

class _LaunchLoader extends StatelessWidget {
  const _LaunchLoader();

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: Center(
        child: SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}
