import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'services/daily_question_service.dart';
import 'services/question_image_sizes.dart';
import 'services/question_service.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Release builds still write debugPrint output to logcat, which would leak
  // auth and payment diagnostics on users' devices. Keep it in debug only.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // IMAGE CACHE CEILING.
  //
  // The app ships 736 question illustrations, most of them 1280 px wide; each
  // one decodes to roughly 3 MB of bitmap. Flutter's default ceiling is 100 MB
  // and 1000 entries, so swiping through a 100-question test would let the
  // cache grow to a hundred megabytes of pixels on a phone that may only have
  // two gigabytes. That is what shows up as stutter and as the app being
  // killed in the background.
  //
  // 40 MB still holds about a dozen decoded questions — four times what the
  // pre-cache window ahead of the current page actually needs.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 << 20;
  PaintingBinding.instance.imageCache.maximumSize = 60;

  final langProvider = LanguageProvider();
  final themeProvider = ThemeProvider();
  final authProvider = AuthProvider();
  final settingsProvider = SettingsProvider();

  // ONLY THE LOOK IS AWAITED BEFORE THE FIRST FRAME.
  //
  // Everything used to be: orientation, Supabase, auth, four preference
  // reads — all before `runApp`, so the process sat on a blank window for as
  // long as the slowest of them took. That blank window IS the cold-start
  // number Play Console grades, and on a cheap phone with no network it was
  // seconds long.
  //
  // Language and theme stay here because they decide what the very first
  // frame looks like, and reading them back after painting would flash a dark
  // screen at someone who chose light. All three share a single
  // SharedPreferences handle, so this is one channel round trip.
  await Future.wait([
    langProvider.init().catchError((_) {}),
    themeProvider.init().catchError((_) {}),
    settingsProvider.init().catchError((_) {}),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: langProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: const AutoTestApp(),
    ),
  );

  // The rest happens with the splash already on screen. AuthGate is built for
  // exactly this: it shows the logo until `authProvider.bootstrapping` clears.
  unawaited(_bootstrap(authProvider, langProvider));
}

/// Start-up work that does not decide what the first frame looks like.
Future<void> _bootstrap(
  AuthProvider authProvider,
  LanguageProvider langProvider,
) async {
  // Every screen is laid out for a portrait phone — the test toolbar, the
  // question number strip and the bottom nav all assume it — so rotation is
  // locked rather than shipping broken landscape layouts. Matches how the
  // previous (Expo) build of this app behaved.
  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).catchError((_) {}),
  );

  // Start-up must never leave the user on a blank screen. A failure here
  // (corrupted session storage, no network on a cold first run) only means
  // the user starts signed out — practice tests work fully offline.
  try {
    await SupabaseService.init();
  } catch (e) {
    debugPrint('main: Supabase init failed: $e');
  }

  // Must follow Supabase init, and clears the splash when it finishes.
  await authProvider.init().catchError((_) {});

  // A 14 KB manifest that only matters once a question card is built, which
  // is several taps away. Loading it before the first frame bought nothing.
  unawaited(QuestionImageSizes.load());

  // Parse the question bank while the user is still reading the home screen,
  // so the first test does not stall on it mid-transition. Deliberately after
  // auth: the splash has to clear first, and this competes for the same
  // isolate scheduling.
  unawaited(QuestionService.warmUp());

  // Re-queues tomorrow's question. It parses the 3.9 MB bank, so it waits
  // until the user has had time to reach a screen — running it at launch put
  // an isolate spawn and a multi-megabyte decode directly against the frames
  // that decide the app's startup grade.
  Future<void>.delayed(const Duration(seconds: 5), () {
    DailyQuestionService.refreshOnLaunch(
      lang: langProvider.lang,
    ).catchError((_) {});
  });
}

class AutoTestApp extends StatefulWidget {
  const AutoTestApp({super.key});

  @override
  State<AutoTestApp> createState() => _AutoTestAppState();
}

class _AutoTestAppState extends State<AutoTestApp> with WidgetsBindingObserver {
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

  /// Parsed question banks are the app's biggest heap tenant — hand them back
  /// when Android asks for memory instead of risking a background kill.
  @override
  void didHaveMemoryPressure() {
    QuestionService.clearCache();
  }

  /// Leaving the app is the last certain moment to persist anything still
  /// only in memory — Android may kill the process without another callback.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      StorageService.flushQuestionStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    // Rebuild the tree when UI language changes.
    context.watch<LanguageProvider>();

    final dark = themeProvider.isDark;
    // Applied here rather than once at start-up: the old fixed light-mode
    // style left dark status-bar icons on the dark theme's dark background,
    // which made the clock and battery unreadable.
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: dark ? AppTheme.surfaceBg : Colors.white,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
    );

    return MaterialApp(
      title: 'AvtoSmart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.mode,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AuthGate(),
    );
  }
}
