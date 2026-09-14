import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import 'pro_paywall_screen.dart';

/// Shows [child] only after a successful PRO check. Blocks content while
/// loading and shows the PRO paywall when the subscription is inactive.
class ProGate extends StatefulWidget {
  final Widget child;
  final String featureTitle;
  final bool isVisible;

  const ProGate({
    super.key,
    required this.child,
    this.featureTitle = 'PRO funksiya',
    this.isVisible = true,
  });

  @override
  State<ProGate> createState() => _ProGateState();
}

class _ProGateState extends State<ProGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  @override
  void didUpdateWidget(ProGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isVisible) {
      _refresh();
    }
  }

  void _refresh() {
    if (!widget.isVisible) return;
    context.read<SubscriptionProvider>().refresh();
  }

  void _retry() {
    if (!mounted) return;
    context.read<SubscriptionProvider>().refresh(force: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    if (sub.isPro) return widget.child;

    // Never flash protected content while verifying PRO in the database —
    // and never flash the PAYWALL either. "Not PRO" and "not asked yet" used
    // to look identical here, so a subscriber opening this screen was shown
    // "buy PRO" for the frame before the answer arrived. Waiting is only
    // wrong once the server has actually said no, or has failed to answer.
    if (sub.loading || (sub.isUnknown && sub.error == null)) {
      return _ProLoadingShell(title: widget.featureTitle);
    }

    return ProPaywallScreen(
      title: widget.featureTitle,
      error: sub.error,
      onRetry: _retry,
    );
  }
}

class _ProLoadingShell extends StatelessWidget {
  final String title;
  const _ProLoadingShell({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.blue,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
