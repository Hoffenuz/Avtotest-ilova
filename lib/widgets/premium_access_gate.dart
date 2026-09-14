import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/auth_screen.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import 'pro_gate.dart';
import 'pro_paywall_screen.dart';

/// Guards topic tests and exam variants: free practice tests stay open;
/// these sections require login + active PRO, with a fresh DB check on
/// every access attempt.
class PremiumAccessGate extends StatefulWidget {
  final Widget child;
  final String featureTitle;
  final bool isVisible;

  const PremiumAccessGate({
    super.key,
    required this.child,
    required this.featureTitle,
    this.isVisible = true,
  });

  @override
  State<PremiumAccessGate> createState() => _PremiumAccessGateState();
}

class _PremiumAccessGateState extends State<PremiumAccessGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAccessAttempt());
  }

  @override
  void didUpdateWidget(PremiumAccessGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _onAccessAttempt();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isVisible) {
      _onAccessAttempt();
    }
  }

  void _onAccessAttempt() {
    if (!widget.isVisible || !mounted) return;
    // ProGate performs the live PRO check for signed-in users.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _openAuth({required bool signUp}) async {
    final ok = await Navigator.push<bool>(
      context,
      AppTheme.slideRoute(AuthScreen(isModal: true, startOnSignUp: signUp)),
    );
    if (ok == true && mounted) {
      await context.read<SubscriptionProvider>().refresh(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    // Not signed in → PRO paywall (content never shown). Registration is the
    // primary action; the sign-in link lives on the auth form itself.
    if (!auth.isLoggedIn) {
      return ProPaywallScreen(
        title: widget.featureTitle,
        onRetry: () => _openAuth(signUp: false),
        primaryAction: ProPaywallAction(
          label: s('create_account_for_pro'),
          icon: Icons.person_add_alt_1_rounded,
          gradient: AppTheme.blueGradient,
          onTap: () => _openAuth(signUp: true),
        ),
        secondaryAction: ProPaywallAction(
          label: s('have_account_sign_in'),
          icon: Icons.login_rounded,
          onTap: () => _openAuth(signUp: false),
        ),
      );
    }

    // Signed in → live PRO check; only show child when subscription is active.
    return ProGate(
      featureTitle: widget.featureTitle,
      isVisible: widget.isVisible,
      child: widget.child,
    );
  }
}

/// What the app currently believes about the user's PRO, for DISPLAY ONLY.
///
/// Use it to decide whether a lock or a "PRO" badge is worth drawing — never
/// to decide whether a test may start. That decision belongs to
/// `launchGuardedTest`, which re-verifies server-side; this is a cached
/// answer and can be out of date in both directions.
bool watchHasPro(BuildContext context) =>
    context.select<SubscriptionProvider, bool>((sub) => sub.isPro);
