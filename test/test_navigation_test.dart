import 'package:avtotest_app/models/question.dart';
import 'package:avtotest_app/providers/auth_provider.dart';
import 'package:avtotest_app/providers/language_provider.dart';
import 'package:avtotest_app/providers/settings_provider.dart';
import 'package:avtotest_app/providers/subscription_provider.dart';
import 'package:avtotest_app/providers/theme_provider.dart';
import 'package:avtotest_app/screens/test_screen.dart';
import 'package:avtotest_app/services/question_service.dart';
import 'package:avtotest_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Moving between questions: no swiping, auto-advance off unless asked for,
/// and a pending auto-advance that respects what the user did meanwhile.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Question> questions;

  setUpAll(() async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      // Text-only questions: a picture would need a real image decode.
      final all = await QuestionService.loadVariantQuestions('v1.json');
      questions = all
          .where((q) => q.mediaUrl == null || q.mediaUrl!.isEmpty)
          .take(3)
          .toList();
    });
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SettingsProvider> pumpTest(
    WidgetTester tester, {
    bool autoAdvance = false,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final settings = SettingsProvider();
    await settings.init();
    await settings.setAutoAdvance(autoAdvance);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: TestScreen(
            title: 'Test',
            loadQuestions: () async => questions,
            testType: 'practice',
            testLabel: 'Test',
            timeLimitMinutes: 25,
            questionLang: 'uz_lat',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return settings;
  }

  Future<void> answerFirstOption(WidgetTester tester, Question q) async {
    await tester.tap(find.text(q.getOptions('uz_lat').first.getText('uz_lat')));
    await tester.pump();
  }

  bool onScreen(WidgetTester tester, Question q) =>
      find.text(q.getText('uz_lat')).hitTestable().evaluate().isNotEmpty;

  /// Ends the test so its periodic timer and buffered writes do not outlive it.
  Future<void> tearDownScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  }

  group('auto-advance setting', () {
    test('is off on a fresh install', () async {
      final settings = SettingsProvider();
      await settings.init();
      expect(settings.autoAdvance, isFalse);
    });

    test('survives a restart once switched on', () async {
      final first = SettingsProvider();
      await first.init();
      await first.setAutoAdvance(true);

      final afterRestart = SettingsProvider();
      await afterRestart.init();
      expect(afterRestart.autoAdvance, isTrue);
    });
  });

  testWidgets('with auto-advance off, an answered question stays put', (
    tester,
  ) async {
    await pumpTest(tester);
    await answerFirstOption(tester, questions[0]);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(onScreen(tester, questions[0]), isTrue);
    expect(onScreen(tester, questions[1]), isFalse);
    await tearDownScreen(tester);
  });

  testWidgets('a sideways swipe does not change the question', (tester) async {
    await pumpTest(tester);
    await tester.fling(
      find.text(questions[0].getText('uz_lat')),
      const Offset(-300, 0),
      1500,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(onScreen(tester, questions[0]), isTrue);
    await tearDownScreen(tester);
  });

  testWidgets('with auto-advance on, the next question opens by itself', (
    tester,
  ) async {
    await pumpTest(tester, autoAdvance: true);
    await answerFirstOption(tester, questions[0]);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(onScreen(tester, questions[1]), isTrue);
    await tearDownScreen(tester);
  });

  testWidgets('switching auto-advance off inside the delay cancels the jump', (
    tester,
  ) async {
    final settings = await pumpTest(tester, autoAdvance: true);
    await answerFirstOption(tester, questions[0]);
    await settings.setAutoAdvance(false);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(onScreen(tester, questions[0]), isTrue);
    await tearDownScreen(tester);
  });

  testWidgets('Keyingi moves on, the number strip comes back', (tester) async {
    await pumpTest(tester);
    // No back button in the footer — Izoh took its place.
    expect(find.text('Oldingi'), findsNothing);

    await tester.tap(find.text('Keyingi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(onScreen(tester, questions[1]), isTrue);

    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(onScreen(tester, questions[0]), isTrue);
    await tearDownScreen(tester);
  });
}
