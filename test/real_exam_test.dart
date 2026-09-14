import 'package:avtotest_app/providers/auth_provider.dart';
import 'package:avtotest_app/providers/language_provider.dart';
import 'package:avtotest_app/providers/subscription_provider.dart';
import 'package:avtotest_app/providers/settings_provider.dart';
import 'package:avtotest_app/providers/theme_provider.dart';
import 'package:avtotest_app/screens/real_exam_screen.dart';
import 'package:avtotest_app/services/question_service.dart';
import 'package:avtotest_app/services/test_session_service.dart';
import 'package:avtotest_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Everything here is about the ways the Real Exam is deliberately unlike the
/// rest of the app (docs/MOBILE-CONTENT-PROMPT.md §3.1) — the differences a
/// well-meaning refactor would "clean up".
///
/// Supabase is never initialized in tests. That is on purpose: it exercises
/// the path where the exam gets no server session and has to run anyway.
///
/// `pumpAndSettle` is never used after the exam opens: the clock ticks once a
/// second forever, so the tree never settles and settling would just time out.
Widget _host({required bool dark}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
    ],
    child: MaterialApp(
      theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const RealExamScreen(),
    ),
  );
}

/// Opens the exam and pumps until the questions are on screen.
///
/// [seed] fixes the draw. The exam is random by design, so two runs compared
/// against each other (light vs dark) have to be told to pick the same twenty
/// questions — otherwise the comparison is between two different exams.
Future<void> _openExam(
  WidgetTester tester, {
  required bool dark,
  int seed = 42,
}) async {
  QuestionService.seedRandomForTest(seed);

  // The bank is a 3.9 MB parse on a background isolate; warm it outside the
  // fake-async zone so the widget's own await resolves in a pump or two.
  await tester.runAsync(QuestionService.loadAllQuestions);
  await tester.runAsync(QuestionService.loadFreeQuestionIds);

  await tester.pumpWidget(_host(dark: dark));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Background colours of every painted box on screen, as a comparable set.
Set<int> _paintedColors(WidgetTester tester) {
  final colors = <int>{};
  for (final element in find.byType(Container).evaluate()) {
    final container = element.widget as Container;
    final decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      colors.add(decoration.color!.toARGB32());
    }
    final color = container.color;
    if (color != null) colors.add(color.toARGB32());
  }
  return colors;
}

/// The longest string on screen — in practice the question itself.
String _questionText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .reduce((a, b) => a.length >= b.length ? a : b);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens with a question, a clock and a number strip', (
    tester,
  ) async {
    await _openExam(tester, dark: false);

    // The number strip is there and numbered from 1. Only the numbers that
    // fit are built — it scrolls — so the far end is not asserted here; the
    // draw size itself is covered in question_assets_test.dart.
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);

    // The clock reads H:MM:SS and starts at 25 minutes.
    expect(find.text('0:25:00'), findsOneWidget);

    // F-keys label the answers, as the official program does.
    expect(find.text('F1'), findsOneWidget);
    expect(find.text('F2'), findsOneWidget);

    expect(_questionText(tester).length, greaterThan(20));
  });

  testWidgets('looks identical in light and dark themes', (tester) async {
    // Several seeds, so the comparison also covers a draw that includes a
    // question with a picture — the image frame was the last thing on this
    // screen still taking its colours from the app theme.
    for (final seed in [1, 7, 42]) {
      await _openExam(tester, dark: false, seed: seed);
      final light = _paintedColors(tester);

      await _openExam(tester, dark: true, seed: seed);
      final dark = _paintedColors(tester);

      expect(light, isNotEmpty, reason: 'seed $seed painted nothing');
      expect(
        dark,
        equals(light),
        reason:
            'seed $seed: the exam screen reproduces one specific program and '
            'must not follow the app theme. A colour that changed here came '
            'from AppTheme.',
      );
    }
  });

  testWidgets('never shows an explanation', (tester) async {
    await _openExam(tester, dark: false);

    await tester.tap(find.text('F1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The explanation UI is not merely hidden — it is not built at all.
    expect(find.byIcon(Icons.menu_book_rounded), findsNothing);
    expect(find.textContaining('Izoh'), findsNothing);
  });

  testWidgets('answering moves on by itself', (tester) async {
    await _openExam(tester, dark: false);
    final first = _questionText(tester);

    await tester.tap(find.text('F1'));
    await tester.pump(); // register the answer
    await tester.pump(const Duration(milliseconds: 1000)); // advance delay
    await tester.pump();

    expect(
      _questionText(tester),
      isNot(first),
      reason: 'the exam should have moved to the next unanswered question',
    );

    // Leave no timer in flight when the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('the exam uses the variant number the website reserves for it', () {
    expect(TestSessionService.realExamVariant, 97);
    expect(TestSessionService.deriveVariant(type: 'exam'), 97);
    // Still distinct from practice (99) and from any real ticket (1..63).
    expect(TestSessionService.deriveVariant(type: 'practice'), 99);
    expect(
      TestSessionService.deriveVariant(type: 'variant', testKey: 'v63'),
      63,
    );
  });

  test('every pool that is not a ticket has a number of its own', () {
    // "difficult" has no digits in it, so it used to fall through to 1 and
    // file itself under exam ticket 1.
    expect(
      TestSessionService.deriveVariant(type: 'difficult', testKey: 'difficult'),
      TestSessionService.difficultPoolVariant,
    );

    final reserved = {
      TestSessionService.realExamVariant,
      TestSessionService.difficultPoolVariant,
      99, // practice
    };
    expect(reserved.length, 3, reason: 'two pools share a number');
    for (final n in reserved) {
      expect(n, greaterThan(63), reason: '$n collides with a real ticket');
      expect(n, lessThanOrEqualTo(100));
    }
  });
}
