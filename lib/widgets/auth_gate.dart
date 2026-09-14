import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/main_shell.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

/// Restores the persisted session on launch, then always shows [MainShell].
/// Login is required only when entering PRO-gated sections (topics / variants).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  /// The user the subscription state was last bound to.
  ///
  /// The binding used to be scheduled from inside a `Consumer`'s builder, so
  /// EVERY auth notification queued another post-frame callback — several per
  /// launch, and one more on every profile refresh. Tracking the id here
  /// keeps the work to the only moment it means anything: when the signed-in
  /// user actually changes.
  String? _boundUserId;
  bool _bound = false;
  bool _bindScheduled = false;

  /// Still deferred to after the frame — `bindAuth` notifies its own
  /// listeners synchronously, and doing that during a build is an error — but
  /// now scheduled only when there is something new to bind.
  void _bindIfChanged(AuthProvider auth) {
    if (_bound && auth.userId == _boundUserId) return;
    if (_bindScheduled) return;
    _bindScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindScheduled = false;
      if (!mounted) return;
      final current = context.read<AuthProvider>();
      _bound = true;
      _boundUserId = current.userId;
      context.read<SubscriptionProvider>().bindAuth(current);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// RE-CHECK PRO EVERY TIME THE APP COMES BACK TO THE FOREGROUND.
  ///
  /// A Payme payment finishes somewhere else — the bank app, a browser, an
  /// SMS confirmation — and the user returns here expecting to be PRO. Until
  /// now nothing asked again on the way back in: the twenty-second cache was
  /// still warm and the auth binding had not changed, so the app went on
  /// believing the answer it had before the payment. Forced, because a cached
  /// -no- is exactly what is wrong at this moment.
  ///
  /// It is one RPC per foreground, on a screen the user is looking at anyway.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    context.read<SubscriptionProvider>().refresh(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        _bindIfChanged(auth);
        return auth.bootstrapping ? const _BootSplash() : const MainShell();
      },
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(height: 72),
            SizedBox(height: 28),
            CircularProgressIndicator(color: AppTheme.blue, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
