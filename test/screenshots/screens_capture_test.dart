// Har ekranni PNG ga chizadi va "overflowed" xatolarini yig'adi — dizayn
// ishidagi "oldin / keyin" solishtiruvi uchun. SHOT_PHASE berilmasa hech
// qanday test ro'yxatdan o'tmaydi, ya'ni oddiy `flutter test` ga ta'sir
// qilmaydi. Qo'lda:
//
//   flutter test test/screenshots/screens_capture_test.dart --dart-define=SHOT_PHASE=before
//   ... --dart-define=SHOT_TEXT_SCALE=1.3   (katta shrift)
//   ... --dart-define=SHOT_ONLY=01_home     (bitta ekran)
//
// Natija: build/screenshots/<phase>/<ekran>__<kenglik>x<balandlik>_<tema>.png
// va build/screenshots/<phase>/overflow.txt.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avtotest_app/models/question.dart';
import 'package:avtotest_app/providers/auth_provider.dart';
import 'package:avtotest_app/providers/language_provider.dart';
import 'package:avtotest_app/providers/settings_provider.dart';
import 'package:avtotest_app/providers/subscription_provider.dart';
import 'package:avtotest_app/providers/theme_provider.dart';
import 'package:avtotest_app/screens/auth_screen.dart';
import 'package:avtotest_app/screens/avtodrom_screen.dart';
import 'package:avtotest_app/screens/difficult_questions_screen.dart';
import 'package:avtotest_app/screens/errors_screen.dart';
import 'package:avtotest_app/screens/main_shell.dart';
import 'package:avtotest_app/screens/memorize_screen.dart';
import 'package:avtotest_app/screens/pro_screen.dart';
import 'package:avtotest_app/screens/question_search_screen.dart';
import 'package:avtotest_app/screens/real_exam_screen.dart';
import 'package:avtotest_app/screens/result_screen.dart';
import 'package:avtotest_app/screens/road_signs_screen.dart';
import 'package:avtotest_app/screens/saved_questions_screen.dart';
import 'package:avtotest_app/screens/test_screen.dart';
import 'package:avtotest_app/screens/topic_list_screen.dart';
import 'package:avtotest_app/screens/topic_stats_screen.dart';
import 'package:avtotest_app/screens/variant_list_screen.dart';
import 'package:avtotest_app/services/question_service.dart';
import 'package:avtotest_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _phase = String.fromEnvironment('SHOT_PHASE');
const String _scaleArg = String.fromEnvironment('SHOT_TEXT_SCALE', defaultValue: '1.0');
const String _only = String.fromEnvironment('SHOT_ONLY');

/// Whole scroll length in one picture (light theme only), for review.
const bool _tall = bool.fromEnvironment('SHOT_TALL');
final double _textScale = double.parse(_scaleArg);
const String _scaleTag = _scaleArg == '1.0' ? '' : '_scale$_scaleArg';

const List<Size> _sizes = _tall ? [Size(360, 2200)] : [Size(360, 800), Size(320, 640)];
const String _fontDir = r'C:\src\flutter\bin\cache\artifacts\material_fonts';

final Directory _out = Directory('build/screenshots/$_phase');
final List<String> _overflows = [];

List<Question> _variant = const [];

Future<void> _loadFonts() async {
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('$_fontDir\\$name').readAsBytes());
  const files = [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
    'roboto-light.ttf',
    'roboto-italic.ttf',
  ];
  final loader = FontLoader('Roboto');
  for (final f in files) {
    loader.addFont(read(f));
  }
  await loader.load();
  final icons = FontLoader('MaterialIcons')..addFont(read('materialicons-regular.otf'));
  await icons.load();
}

class _Shot {
  final String name;
  final Widget Function() build;

  /// After the first frame: e.g. switching a MainShell tab.
  final Future<void> Function(WidgetTester tester)? after;

  /// Signed-in subscriber instead of a guest.
  final bool pro;

  /// SharedPreferences the screen starts with (e.g. finished tests).
  final Map<String, Object> prefs;
  const _Shot(this.name, this.build, {this.after, this.pro = false, this.prefs = const {}});
}

/// Decided subscription state — no network (as in pro_visibility_test).
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

class _SignedIn extends AuthProvider {
  @override
  bool get isLoggedIn => true;
}

final Map<String, Object> _sampleResults = {
  'practice_test_results': jsonEncode([
    for (final (i, c) in [(0, 19), (1, 15), (2, 18), (3, 12)])
      TestResult(
        type: i.isEven ? 'variant' : 'practice',
        testKey: i.isEven ? 'v${i + 1}' : null,
        label: i.isEven ? '${i + 1}-variant' : 'Test ishlash',
        totalQuestions: 20,
        correctAnswers: c,
        timeSpentSeconds: 900,
        date: DateTime(2026, 9, 25 - i),
        isCompleted: true,
      ).toJson(),
  ]),
};

final GlobalKey<MainShellState> _shellKey = GlobalKey<MainShellState>();

Future<void> Function(WidgetTester) _tab(int index) => (tester) async {
      _shellKey.currentState?.switchTab(index);
      await tester.pump();
    };

List<_Shot> _shots() => [
      _Shot('01_home', () => MainShell(key: _shellKey)),
      _Shot('01b_home_pro_results', () => MainShell(key: _shellKey), pro: true, prefs: _sampleResults),
      _Shot('02_sections', () => MainShell(key: _shellKey), after: _tab(1)),
      _Shot('03_practice_setup', () => MainShell(key: _shellKey), after: _tab(2)),
      _Shot('04_profile', () => MainShell(key: _shellKey), after: _tab(3)),
      _Shot('05_variant_list', () => const VariantListScreen()),
      _Shot('06_topic_list', () => const TopicListScreen()),
      _Shot(
        '07_test',
        () => TestScreen(
          title: '1-variant',
          loadQuestions: () async => _variant,
          testType: 'variant',
          testLabel: '1-variant',
          testKey: 'v1',
          timeLimitMinutes: 25,
        ),
      ),
      _Shot(
        '08_result',
        () => ResultScreen(
          result: TestResult(
            type: 'variant',
            testKey: 'v1',
            label: '1-variant',
            totalQuestions: 20,
            correctAnswers: 15,
            timeSpentSeconds: 17 * 60 + 12,
            date: DateTime(2026, 9, 26, 14, 30),
            isCompleted: true,
          ),
          questions: _variant,
          selectedAnswers: {for (final q in _variant) q.globalId: 0},
          incorrectIds: _variant.take(5).map((q) => q.globalId).toSet(),
          testTitle: '1-variant',
        ),
      ),
      _Shot('09_real_exam', () => const RealExamScreen()),
      _Shot('10_errors', () => const ErrorsScreen()),
      _Shot('11_saved_questions', () => const SavedQuestionsScreen()),
      _Shot('12_difficult_questions', () => const DifficultQuestionsScreen()),
      _Shot('13_road_signs', () => const RoadSignsScreen()),
      _Shot('14_avtodrom', () => const AvtodromScreen()),
      _Shot('15_memorize', () => const MemorizeScreen()),
      _Shot('16_question_search', () => const QuestionSearchScreen()),
      _Shot('17_pro', () => const ProScreen()),
      _Shot('18_auth_login', () => const AuthScreen()),
      _Shot('19_auth_signup', () => const AuthScreen(startOnSignUp: true)),
      _Shot('20_topic_stats', () => const TopicStatsScreen()),
    ];

/// A component TextStyle with no family (AppBar title, button labels) falls
/// back to boxes under flutter_test; on a phone it falls back to Roboto.
ThemeData _withRoboto(ThemeData t) {
  TextStyle? f(TextStyle? s) => s?.copyWith(fontFamily: 'Roboto');
  ButtonStyle? b(ButtonStyle? s) {
    final style = s?.textStyle?.resolve(<WidgetState>{});
    return style == null ? s : s!.copyWith(textStyle: WidgetStatePropertyAll(f(style)));
  }

  return t.copyWith(
    appBarTheme: t.appBarTheme.copyWith(titleTextStyle: f(t.appBarTheme.titleTextStyle)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: b(t.elevatedButtonTheme.style)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: b(t.outlinedButtonTheme.style)),
    textButtonTheme: TextButtonThemeData(style: b(t.textButtonTheme.style)),
    dialogTheme: t.dialogTheme.copyWith(
      titleTextStyle: f(t.dialogTheme.titleTextStyle),
      contentTextStyle: f(t.dialogTheme.contentTextStyle),
    ),
    snackBarTheme: t.snackBarTheme.copyWith(contentTextStyle: f(t.snackBarTheme.contentTextStyle)),
    inputDecorationTheme: t.inputDecorationTheme.copyWith(
      labelStyle: f(t.inputDecorationTheme.labelStyle),
      hintStyle: f(t.inputDecorationTheme.hintStyle),
    ),
    bottomNavigationBarTheme: t.bottomNavigationBarTheme.copyWith(
      selectedLabelStyle: f(t.bottomNavigationBarTheme.selectedLabelStyle),
      unselectedLabelStyle: f(t.bottomNavigationBarTheme.unselectedLabelStyle),
    ),
  );
}

Widget _host(Widget child, {required bool dark, bool pro = false}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider<AuthProvider>(create: (_) => pro ? _SignedIn() : AuthProvider()),
      ChangeNotifierProvider<SubscriptionProvider>(
        create: (_) => pro ? _Sub(pro: true) : SubscriptionProvider(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _withRoboto(dark ? AppTheme.darkTheme : AppTheme.lightTheme),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_textScale),
        ),
        child: child!,
      ),
      home: child,
    ),
  );
}

/// Images and SVGs decode on real async — let them finish, then repaint.
Future<void> _settleAssets(WidgetTester tester) async {
  for (var round = 0; round < 3; round++) {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        await precacheImage(image.image, element).catchError((_) {});
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }
}

Future<void> _capture(WidgetTester tester, String file) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${_out.path}/$file').writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_phase.isEmpty) return;

  setUpAll(() async {
    await _loadFonts();
    _out.createSync(recursive: true);
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      _variant = await QuestionService.loadVariantQuestions('v1.json');
      await QuestionService.loadAllQuestions();
    });
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDownAll(() {
    File('${_out.path}/overflow$_scaleTag${_tall ? '_tall' : ''}.txt').writeAsStringSync(
      _overflows.isEmpty ? 'overflow yo‘q\n' : '${_overflows.join('\n')}\n',
    );
  });

  for (final shot in _shots()) {
    if (_only.isNotEmpty && !shot.name.contains(_only)) continue;
    for (final size in _sizes) {
      for (final dark in _tall ? const [false] : const [false, true]) {
        final theme = dark ? 'dark' : 'light';
        final tag = '${shot.name}__${size.width.toInt()}x${size.height.toInt()}_$theme$_scaleTag';
        testWidgets(tag, (tester) async {
          final errors = <String>[];
          final original = FlutterError.onError;
          FlutterError.onError = (details) {
            final text = details.exceptionAsString().split('\n').first;
            errors.add(text);
          };
          try {
            tester.view.physicalSize = size * 2;
            tester.view.devicePixelRatio = 2.0;
            if (shot.prefs.isNotEmpty) SharedPreferences.setMockInitialValues(shot.prefs);
            await tester.pumpWidget(
              RepaintBoundary(
                key: const ValueKey('shot'),
                child: _host(shot.build(), dark: dark, pro: shot.pro),
              ),
            );
            for (var i = 0; i < 8; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            if (shot.after != null) await shot.after!(tester);
            await _settleAssets(tester);
            await _capture(tester, '$tag.png');
          } finally {
            // Screens with timers (test, real exam) cancel them in dispose.
            // 3 s: the result screen's delayed review prompt is 2.2 s.
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 3));
            FlutterError.onError = original;
            tester.view.reset();
          }
          for (final e in errors.toSet()) {
            _overflows.add('$tag: $e');
          }
        });
      }
    }
  }
}
