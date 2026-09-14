import 'package:avtotest_app/providers/auth_provider.dart';
import 'package:avtotest_app/providers/language_provider.dart';
import 'package:avtotest_app/providers/subscription_provider.dart';
import 'package:avtotest_app/providers/settings_provider.dart';
import 'package:avtotest_app/providers/theme_provider.dart';
import 'package:avtotest_app/screens/avtodrom_screen.dart';
import 'package:avtotest_app/screens/home_screen.dart';
import 'package:avtotest_app/screens/main_shell.dart';
import 'package:avtotest_app/screens/memorize_screen.dart';
import 'package:avtotest_app/screens/profile_screen.dart';
import 'package:avtotest_app/screens/sections_screen.dart';
import 'package:avtotest_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 320 dp is the narrowest phone still in real use, and it is where layouts
/// break first: the website overflowed by 4 px there and gave the whole page a
/// horizontal scrollbar (docs/MOBILE-CONTENT-PROMPT.md §7.3).
///
/// A Flutter overflow is not silent — it throws — so pumping each screen at
/// 320×640 in both themes and both alphabets is enough to catch it. Russian is
/// included deliberately: it is the longest of the three translations, so it
/// is the one that overflows.
const Size _narrowPhone = Size(320, 640);

Widget _host(Widget child, {required bool dark}) {
  return MultiProvider(
    providers: [
      // Default language (uz_lat); `init()` is skipped so the test never
      // reaches StorageService, which needs platform plugins.
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
    ],
    child: MaterialApp(
      theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: child,
    ),
  );
}

Future<void> _pumpAt(
  WidgetTester tester,
  Widget screen, {
  required bool dark,
  bool settle = true,

  /// A taller viewport lays a long list out in one go, so a test can assert
  /// on rows without driving the scroller. WIDTH is what these tests are
  /// about — 320 dp is where things overflow — and it stays 320 either way.
  bool tall = false,
}) async {
  tester.view.physicalSize = tall ? const Size(320, 1800) : _narrowPhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(screen, dark: dark));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Screens that host a subscription check keep a progress spinner turning
    // while it resolves — and it never resolves here, because Supabase is not
    // initialized in tests. Fixed pumps get the layout built without waiting
    // for an animation that has no end.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The settings screen waits on the stored results list before it renders
  // anything; without a backing store that future never completes and the
  // screen stays a spinner.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Sections list fits a 320 dp phone (light)', (tester) async {
    await _pumpAt(tester, const SectionsScreen(), dark: false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sections list fits a 320 dp phone (dark)', (tester) async {
    await _pumpAt(tester, const SectionsScreen(), dark: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Yodlash kerak fits a 320 dp phone', (tester) async {
    await _pumpAt(tester, const MemorizeScreen(), dark: false);
    expect(tester.takeException(), isNull);
    // The first topic opens by default, so rows are actually laid out rather
    // than the test passing on a screen full of collapsed headers.
    expect(find.textContaining('km/soat'), findsWidgets);
  });

  testWidgets('Avtodrom fits a 320 dp phone', (tester) async {
    await _pumpAt(tester, const AvtodromScreen(), dark: false);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('ball'), findsWidgets);
  });

  testWidgets('Home fits a 320 dp phone and offers the quick actions', (
    tester,
  ) async {
    await _pumpAt(tester, const HomeScreen(), dark: true, settle: false);
    expect(tester.takeException(), isNull);

    // The two the exam-day routine is built around, reachable from the first
    // screen rather than a tab away.
    expect(find.text('Real imtihon'), findsOneWidget);
    expect(find.text('Xatolarim'), findsOneWidget);
  });

  testWidgets('the four-tab bar fits a 320 dp phone', (tester) async {
    // Four labels across 320 dp is the tightest thing in the app.
    await _pumpAt(tester, const MainShell(), dark: false, settle: false);
    expect(tester.takeException(), isNull);

    // All four destinations are reachable.
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    // Two matches on purpose: the nav item and the home screen's practice
    // card share this glyph.
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsWidgets);

    // Left to right: Asosiy · Bo'limlar · Test ishlash · Sozlamalar. Compared
    // by actual on-screen position, so reordering the Row fails the test
    // rather than quietly shipping.
    final bar = tester.getRect(find.byIcon(Icons.settings_rounded));
    double xOf(IconData icon) {
      return tester
          .getRect(
            find.descendant(
              of: find.byType(SafeArea),
              matching: find.byIcon(icon),
              matchRoot: true,
            ),
          )
          .center
          .dx;
    }

    final home = xOf(Icons.home_rounded);
    final sections = xOf(Icons.apps_rounded);
    final settings = bar.center.dx;
    expect(home, lessThan(sections));
    expect(sections, lessThan(settings));
  });

  testWidgets('Settings is one flat list of uniform rows', (tester) async {
    await _pumpAt(
      tester,
      const ProfileScreen(),
      dark: false,
      settle: false,
      tall: true,
    );
    expect(tester.takeException(), isNull);

    // Nothing to expand any more: every setting is on screen, one tap from
    // being changed, and each of these is a row of the same shape.
    expect(find.text('Til'), findsOneWidget);
    expect(find.text('Mavzu'), findsOneWidget);
    expect(find.text("Savol matni o'lchami"), findsOneWidget);
    expect(find.text('Xatodan keyin izoh'), findsOneWidget);
    expect(find.text('Kunlik savol'), findsOneWidget);

    // Account actions live behind the pencil on the identity card, not in a
    // group of their own.
    expect(find.text("Parolni o'zgartirish"), findsNothing);
  });

  testWidgets('the explanation-after-a-mistake switch is off by default', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      const ProfileScreen(),
      dark: false,
      settle: false,
      tall: true,
    );

    final row = find.ancestor(
      of: find.text('Xatodan keyin izoh'),
      matching: find.byType(Row),
    );
    final toggle = tester.widget<Switch>(
      find.descendant(of: row.first, matching: find.byType(Switch)),
    );
    expect(
      toggle.value,
      isFalse,
      reason: 'a sheet opening on every mistake must be opted into',
    );
  });
}
