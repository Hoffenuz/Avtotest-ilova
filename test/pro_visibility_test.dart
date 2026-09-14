import 'package:avtotest_app/providers/auth_provider.dart';
import 'package:avtotest_app/providers/language_provider.dart';
import 'package:avtotest_app/providers/subscription_provider.dart';
import 'package:avtotest_app/providers/settings_provider.dart';
import 'package:avtotest_app/providers/theme_provider.dart';
import 'package:avtotest_app/models/question.dart';
import 'package:avtotest_app/screens/sections_screen.dart';
import 'package:avtotest_app/widgets/explanation_panel.dart';
import 'package:avtotest_app/screens/topic_list_screen.dart';
import 'package:avtotest_app/screens/variant_list_screen.dart';
import 'package:avtotest_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A subscription state that is simply decided, so a screen can be rendered
/// as a subscriber sees it. Every network path is stubbed out; only the
/// getters the UI reads are overridden.
class _Sub extends SubscriptionProvider {
  _Sub({required this.pro});
  final bool pro;

  @override
  bool get isPro => pro;
  @override
  bool get isUnknown => false;
  @override
  bool get isDeniedForSure => !pro;
  @override
  bool get isFresh => true;
  @override
  bool get loading => false;

  @override
  Future<void> refresh({bool force = false}) async {}
  @override
  Future<void> refreshIfUnknown() async {}
}

Widget _host(Widget child, {required bool pro}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider<SubscriptionProvider>.value(value: _Sub(pro: pro)),
    ],
    child: MaterialApp(theme: AppTheme.darkTheme, home: child),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required bool pro,
}) async {
  await tester.pumpWidget(_host(screen, pro: pro));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('a subscriber is never told to buy PRO', () {
    testWidgets('Sections shows no PRO badges', (tester) async {
      await _pump(tester, const SectionsScreen(), pro: true);
      expect(
        find.text('PRO'),
        findsNothing,
        reason: 'a paying user was being reminded on every row',
      );
    });

    testWidgets('every exam ticket is unlocked', (tester) async {
      await _pump(tester, const VariantListScreen(), pro: true);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
      // The "first five are free" line is meaningless once everything is.
      expect(find.textContaining('bepul'), findsNothing);
    });

    testWidgets('every topic is unlocked', (tester) async {
      await _pump(tester, const TopicListScreen(), pro: true);
      expect(find.text('PRO'), findsNothing);
      expect(find.textContaining('bepul'), findsNothing);
    });
  });

  group('a free user still sees the line', () {
    testWidgets('Sections marks the PRO-only rows', (tester) async {
      await _pump(tester, const SectionsScreen(), pro: false);
      expect(find.text('PRO'), findsWidgets);
    });

    testWidgets('locked tickets carry a lock and an explanation', (
      tester,
    ) async {
      await _pump(tester, const VariantListScreen(), pro: false);
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      expect(find.textContaining('bepul'), findsOneWidget);
    });

    testWidgets('locked topics carry a PRO badge', (tester) async {
      await _pump(tester, const TopicListScreen(), pro: false);
      expect(find.text('PRO'), findsWidgets);
    });
  });

  group('a signed-out user gets the offer, never a spinner', () {
    // THE HANG: `isUnknown` used to mean "we hold no access row", and a row
    // never arrives for someone with no account — so the explanation panel
    // waited on an answer that could not come. Tapping the button spun
    // forever instead of showing what PRO is for.
    Widget hostPanel(SubscriptionProvider sub) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider<SubscriptionProvider>.value(value: sub),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ExplanationPanel(
              question: Question(
                globalId: 't_1_q_1',
                ticketNum: 1,
                order: 1,
                texts: const {'uz_lat': 'Savol'},
                options: const {'uz_lat': <Option>[]},
                izoh: const {'uz_lat': 'Izoh matni'},
              ),
              lang: 'uz_lat',
              uiLang: 'uz_lat',
            ),
          ),
        ),
      );
    }

    testWidgets('the PRO offer is shown, not a progress indicator', (
      tester,
    ) async {
      // Exactly what AuthGate does for a launch with nobody signed in.
      final sub = SubscriptionProvider()..bindAuth(AuthProvider());

      await tester.pumpWidget(hostPanel(sub));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'this is the spinner that never stopped',
      );
      expect(find.text('PRO'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('the explanation itself is never leaked to them', (
      tester,
    ) async {
      final sub = SubscriptionProvider()..bindAuth(AuthProvider());

      await tester.pumpWidget(hostPanel(sub));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Izoh matni'), findsNothing);
    });
  });
}
