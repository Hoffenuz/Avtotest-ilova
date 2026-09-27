import 'package:avtotest_app/providers/auth_provider.dart';
import 'package:avtotest_app/providers/language_provider.dart';
import 'package:avtotest_app/providers/readiness_provider.dart';
import 'package:avtotest_app/providers/theme_provider.dart';
import 'package:avtotest_app/services/app_strings.dart';
import 'package:avtotest_app/services/readiness_service.dart';
import 'package:avtotest_app/theme/app_theme.dart';
import 'package:avtotest_app/widgets/readiness_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A server row as `get_user_readiness()` returns it.
Map<String, dynamic> row({
  int percent = 62,
  int level = 3,
  int? next = 70,
  int? toNext = 8,
  int streak = 4,
  int seen = 240,
  int review = 17,
  bool hasData = true,
}) => {
  'readiness_percent': percent,
  'accuracy_percent': 78,
  'coverage_percent': 19,
  'variants_percent': 45,
  'mastery_percent': 60,
  'tests_percent': 70,
  'tests_total': 35,
  'tests_today': 2,
  'tests_target': 50,
  'questions_seen': seen,
  'questions_total': 1260,
  'questions_mastered': 144,
  'questions_to_review': review,
  'variants_passed': 9,
  'variants_attempted': 14,
  'variants_total': 20,
  'level_index': level,
  'level_min_percent': 50,
  'level_next_percent': next,
  'percent_to_next': toNext,
  'exam_date': '2026-10-15',
  'days_to_exam': 18,
  'streak_days': streak,
  'has_data': hasData,
};

/// Fixed state, no network.
class FakeReadiness extends ReadinessProvider {
  FakeReadiness({this.fixedData, this.fixedLoading = false, this.on = true});
  final Readiness? fixedData;
  final bool fixedLoading;
  final bool on;
  @override
  bool get active => on;
  @override
  Readiness? get data => fixedLoading ? null : fixedData;
  @override
  bool get loading => on && fixedLoading;
  @override
  bool get unavailable => on && !fixedLoading && fixedData == null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  wiringTests();

  group('levels', () {
    test('are exactly the website\'s READINESS_LEVELS', () {
      expect(
        [
          for (final l in readinessLevels)
            (l.index, l.minPercent, l.maxPercent),
        ],
        [
          (1, 0, 29),
          (2, 30, 49),
          (3, 50, 69),
          (4, 70, 84),
          (5, 85, 94),
          (6, 95, 100),
        ],
      );
    });

    test('names match the website in all three languages', () {
      expect(
        [for (final l in readinessLevels) AppStrings.get(l.labelKey, 'uz_lat')],
        [
          "Boshlang'ich",
          "O'rta",
          'Yuqori',
          'Malakali',
          'Professional',
          'Legenda',
        ],
      );
      for (final lang in ['uz_cyr', 'ru']) {
        for (final l in readinessLevels) {
          final name = AppStrings.get(l.labelKey, lang);
          expect(name, isNot(l.labelKey), reason: '$lang ${l.labelKey}');
          expect(name, isNotEmpty);
        }
      }
    });
  });

  test('colour follows the percent: 40 / 65 / 85', () {
    Color ring(int p) => ReadinessTone.of(p, dark: false).ring;
    expect(ring(39), const Color(0xFFEF4444));
    expect(ring(40), const Color(0xFFF59E0B));
    expect(ring(64), const Color(0xFFF59E0B));
    expect(ring(65), const Color(0xFF22C55E));
    expect(ring(84), const Color(0xFF22C55E));
    expect(ring(85), const Color(0xFF10B981));
  });

  group('server row', () {
    test('is read as sent, level taken from the server', () {
      final r = Readiness.fromRow(row());
      expect(r.readinessPercent, 62);
      expect(r.levelIndex, 3);
      expect(r.percentToNext, 8);
      expect(r.examDate, DateTime(2026, 10, 15));
      expect(r.hasData, isTrue);
    });

    test('the bar shows progress inside the current level', () {
      expect(Readiness.fromRow(row()).progressWithinLevel, closeTo(0.6, 1e-9));
      final top = Readiness.fromRow(
        row(percent: 97, level: 6, next: null, toNext: null),
      );
      expect(top.progressWithinLevel, closeTo(0.4, 1e-9));
    });

    test('nulls for the top level are kept, not turned into 0', () {
      final top = Readiness.fromRow(
        row(percent: 97, level: 6, next: null, toNext: null),
      );
      expect(top.levelNextPercent, isNull);
      expect(top.percentToNext, isNull);
    });
  });

  Future<void> pump(
    WidgetTester tester,
    ReadinessProvider readiness, {
    double textScale = 1.0,
    Widget? child,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<ReadinessProvider>.value(value: readiness),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: c!,
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  child ??
                  Column(
                    children: [
                      ReadinessStripSlot(onOpen: () {}, onStart: () {}),
                      const Text('below'),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
  }

  for (final scale in [1.0, 1.3]) {
    testWidgets('home strip keeps one height in every state (x$scale)', (
      tester,
    ) async {
      final heights = <double>[];
      for (final state in [
        FakeReadiness(fixedLoading: true),
        FakeReadiness(fixedData: Readiness.fromRow(row(hasData: false))),
        FakeReadiness(),
        FakeReadiness(fixedData: Readiness.fromRow(row())),
      ]) {
        await pump(tester, state, textScale: scale);
        expect(tester.takeException(), isNull);
        heights.add(tester.getSize(find.byType(ReadinessStrip)).height);
        // The text below sits at the same place, too.
        heights.add(tester.getTopLeft(find.text('below')).dy);
      }
      final strip = [for (var i = 0; i < heights.length; i += 2) heights[i]];
      final below = [for (var i = 1; i < heights.length; i += 2) heights[i]];
      expect(strip.toSet(), hasLength(1), reason: 'strip heights $strip');
      expect(below.toSet(), hasLength(1), reason: 'content moved: $below');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('no strip and no gap for a guest', (tester) async {
    await pump(tester, FakeReadiness(on: false));
    expect(find.byType(ReadinessStrip), findsNothing);
    expect(tester.getTopLeft(find.text('below')).dy, 16);
  });

  testWidgets('no test yet: an invitation, never "0%"', (tester) async {
    await pump(
      tester,
      FakeReadiness(fixedData: Readiness.fromRow(row(hasData: false))),
    );
    expect(find.text('Boshlash'), findsOneWidget);
    expect(find.textContaining('0%'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('strip: level name first, what is left to the next level', (
    tester,
  ) async {
    await pump(tester, FakeReadiness(fixedData: Readiness.fromRow(row())));
    expect(find.text('Yuqori'), findsOneWidget);
    expect(find.text('Malakali darajasiga 8% qoldi'), findsOneWidget);
    expect(find.text('4 kun'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('card: unmeasured metrics are hidden, not shown as 0%', (
    tester,
  ) async {
    await pump(
      tester,
      FakeReadiness(fixedData: Readiness.fromRow(row(seen: 0, review: 0))),
      child: SingleChildScrollView(
        child: ReadinessCard(onStart: () {}, onReview: () {}),
      ),
    );
    expect(find.textContaining('Variantlar'), findsOneWidget);
    expect(find.textContaining('Bazani qamrash'), findsNothing);
    expect(find.textContaining('Mustahkamlik'), findsNothing);
    expect(find.text('Xatolarim'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('levels sheet lists all six, marks the current one', (
    tester,
  ) async {
    await pump(
      tester,
      FakeReadiness(fixedData: Readiness.fromRow(row(review: 0))),
      child: SingleChildScrollView(
        child: ReadinessCard(onStart: () {}, onReview: () {}),
      ),
    );
    await tester.tap(find.text('Darajalar'));
    await tester.pumpAndSettle();
    for (final name in [
      "Boshlang'ich",
      "O'rta",
      'Malakali',
      'Professional',
      'Legenda',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Hozir'), findsOneWidget);
    // Reached: levels 1–3 at 62%.
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
  });
}

class _SwitchableAuth extends AuthProvider {
  String? id;
  @override
  String? get userId => id;
  @override
  bool get isLoggedIn => id != null;
  void signIn(String value) {
    id = value;
    notifyListeners();
  }
}

void wiringTests() {
  testWidgets('signing in while the home is on screen: no build error, and '
      'an unreachable server ends in a neutral state', (tester) async {
    final auth = _SwitchableAuth();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProxyProvider<AuthProvider, ReadinessProvider>(
            create: (_) => ReadinessProvider(),
            update: (_, a, r) => r!..attach(a.userId),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ReadinessStripSlot(onOpen: () {}, onStart: () {}),
          ),
        ),
      ),
    );
    expect(find.byType(ReadinessStrip), findsNothing);

    auth.signIn('user-1');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ReadinessStrip), findsOneWidget);

    // Supabase is not initialised here: the fetch fails, the strip settles.
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.text('Imtihonga tayyorgarlik'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
