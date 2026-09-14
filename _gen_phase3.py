#!/usr/bin/env python3
"""Phase 3: light-blue recolor, auto-advance layout, consistent buttons, lazy loading, polished header."""
import os

BASE = os.path.dirname(os.path.abspath(__file__))

def write(rel, content):
    p = os.path.join(BASE, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'  wrote {rel}')

# ═══════════════════════════════════════════════════════════════
# 1. THEME — purple → light blue, consistent radiusMd for all buttons
# ═══════════════════════════════════════════════════════════════
write('lib/theme/app_theme.dart', r"""import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ──── PRIMARY PALETTE (light blue + orange) ────
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFF60A5FA);
  static const Color blueDark = Color(0xFF2563EB);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFB923C);
  static const Color orangeDark = Color(0xFFEA580C);

  // ──── DARK PALETTE ────
  static const Color scaffoldBg = Color(0xFF0B1120);
  static const Color cardBg = Color(0xFF15202E);
  static const Color cardBgLight = Color(0xFF1C2A3D);
  static const Color surfaceBg = Color(0xFF101B2C);

  // ──── LIGHT PALETTE ────
  static const Color lightScaffoldBg = Color(0xFFF5F7FA);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightSurfaceBg = Color(0xFFEDF0F5);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BFCF);
  static const Color textMuted = Color(0xFF6B7B8F);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // Gradients
  static const LinearGradient blueGradient = LinearGradient(
    colors: [blueLight, blueDark],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orangeLight, orangeDark],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [blue, orange],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Consistent radius — ALL interactive elements use radiusMd (12)
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 28.0;

  // ──── CONTEXT-AWARE HELPERS ────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color card(BuildContext context) =>
      isDark(context) ? cardBg : lightCardBg;

  static Color surface(BuildContext context) =>
      isDark(context) ? surfaceBg : lightSurfaceBg;

  static Color textP(BuildContext context) =>
      isDark(context) ? textPrimary : lightTextPrimary;

  static Color textS(BuildContext context) =>
      isDark(context) ? textSecondary : lightTextSecondary;

  static Color textM(BuildContext context) =>
      isDark(context) ? textMuted : lightTextMuted;

  static Color border(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06);

  static Color primary(BuildContext context) => blue;

  static Color accent(BuildContext context) => orange;

  static BoxDecoration cardDeco(BuildContext context,
      {double radius = radiusLg, Border? b}) {
    final dark = isDark(context);
    return BoxDecoration(
      color: dark ? cardBg : lightCardBg,
      borderRadius: BorderRadius.circular(radius),
      border: b ?? Border.all(color: border(context)),
      boxShadow: dark
          ? null
          : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 2))],
    );
  }

  static BoxDecoration glassDeco(BuildContext context,
      {double radius = radiusMd}) {
    final dark = isDark(context);
    return BoxDecoration(
      color: dark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: dark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.08),
      ),
    );
  }

  // ──── DARK THEME ────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: const ColorScheme.dark(
        primary: blue,
        secondary: orange,
        surface: cardBg,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true, elevation: 0,
        backgroundColor: Colors.transparent, foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: cardBg, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          side: const BorderSide(color: blue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMd)),
          )),
      iconTheme: const IconThemeData(color: textSecondary),
      dividerTheme:
          DividerThemeData(color: Colors.white.withValues(alpha: 0.06)),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl)),
        titleTextStyle: const TextStyle(
            color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        contentTextStyle:
            const TextStyle(color: textSecondary, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBgLight,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surfaceBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: blue)),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      popupMenuTheme: PopupMenuThemeData(
          color: cardBgLight,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd))),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceBg,
        selectedItemColor: blue,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed, elevation: 0,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
    );
  }

  // ──── LIGHT THEME ────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: lightScaffoldBg,
      colorScheme: ColorScheme.light(
        primary: blue,
        secondary: orange,
        surface: lightCardBg,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true, elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: lightTextPrimary,
        titleTextStyle: TextStyle(
            color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: lightCardBg, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          side: const BorderSide(color: blue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: blue,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusMd)),
          )),
      iconTheme: const IconThemeData(color: lightTextSecondary),
      dividerTheme:
          DividerThemeData(color: Colors.black.withValues(alpha: 0.06)),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCardBg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl)),
        titleTextStyle: const TextStyle(
            color: lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600),
        contentTextStyle:
            const TextStyle(color: lightTextSecondary, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightCardBg,
        contentTextStyle: const TextStyle(color: lightTextPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: lightSurfaceBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide:
                BorderSide(color: Colors.black.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide:
                BorderSide(color: Colors.black.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            borderSide: const BorderSide(color: blue)),
        labelStyle: const TextStyle(color: lightTextMuted),
        hintStyle: const TextStyle(color: lightTextMuted),
      ),
      popupMenuTheme: PopupMenuThemeData(
          color: lightCardBg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd))),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightCardBg,
        selectedItemColor: blue,
        unselectedItemColor: lightTextMuted,
        type: BottomNavigationBarType.fixed, elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  // Page transitions
  static Route<T> fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
            opacity: CurvedAnimation(
                parent: animation, curve: Curves.easeOut),
            child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> slideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
            position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
""")

# ═══════════════════════════════════════════════════════════════
# 2. HOME SCREEN — polished header, lazy loading, consistent shapes
# ═══════════════════════════════════════════════════════════════
write('lib/screens/home_screen.dart', r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'topic_list_screen.dart';
import 'variant_list_screen.dart';
import 'practice_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  int _totalTests = 0;
  int _passedTests = 0;
  double _avgScore = 0;
  List<TestResult> _recentResults = [];
  bool _showAllResults = false;
  bool _statsLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final results = await StorageService.getResults();
    if (!mounted) return;
    final completed = results.where((r) => r.isCompleted).toList();
    setState(() {
      _totalTests = completed.length;
      _passedTests = completed.where((r) => r.isPassed).length;
      _avgScore = _totalTests > 0
          ? completed.fold<double>(0, (sum, r) => sum + r.percentage) /
                _totalTests
          : 0;
      _recentResults = results;
      _statsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>().lang;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: AppTheme.blue,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildTopBar(lang),
                      const SizedBox(height: 20),
                      _buildHeroCard(lang),
                      const SizedBox(height: 20),
                      _buildMenuCards(lang),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
              // Lazy-loaded results section
              if (_statsLoaded)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResultsSection(lang),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Polished Top Bar ───
  Widget _buildTopBar(String lang) {
    final dark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: dark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: AppTheme.blueGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Center(
              child: Icon(Icons.directions_car_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.get('app_title', lang),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textP(context),
                        letterSpacing: -0.3)),
                Text(AppStrings.get('hero_subtitle', lang).split('\n').first,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textM(context)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                context.findAncestorStateOfType<MainShellState>()?.switchTab(3),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Icon(Icons.settings_outlined,
                  color: AppTheme.textS(context), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero Card — gradient border accent ───
  Widget _buildHeroCard(String lang) {
    final dark = AppTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl + 2),
        gradient: AppTheme.blueGradient,
      ),
      padding: const EdgeInsets.all(1.5), // gradient border
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: AppTheme.blueGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(
                    color: AppTheme.blue.withValues(alpha: 0.25),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.directions_car_rounded,
                  size: 32, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(AppStrings.get('hero_title', lang),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: AppTheme.textP(context), height: 1.3,
                    letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(AppStrings.get('hero_subtitle', lang),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: AppTheme.textM(context), height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCards(String lang) {
    return Column(
      children: [
        _MenuActionCard(
          icon: Icons.play_circle_filled_rounded,
          title: AppStrings.get('menu_test', lang),
          subtitle: AppStrings.get('menu_test_sub', lang),
          gradient: AppTheme.blueGradient,
          isHighlighted: true,
          onTap: () => Navigator.push(context,
              AppTheme.slideRoute(const PracticeSetupScreen())),
        ),
        const SizedBox(height: 12),
        _MenuActionCard(
          icon: Icons.menu_book_rounded,
          title: AppStrings.get('menu_topics', lang),
          subtitle: AppStrings.get('menu_topics_sub', lang),
          iconColor: AppTheme.orange,
          onTap: () => Navigator.push(context,
              AppTheme.slideRoute(const TopicListScreen())),
        ),
        const SizedBox(height: 12),
        _MenuActionCard(
          icon: Icons.quiz_rounded,
          title: AppStrings.get('menu_variants', lang),
          subtitle: AppStrings.get('menu_variants_sub', lang),
          iconColor: AppTheme.blue,
          onTap: () => Navigator.push(context,
              AppTheme.slideRoute(const VariantListScreen())),
        ),
      ],
    );
  }

  Widget _buildResultsSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.get('your_results', lang),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: AppTheme.textP(context))),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatMiniCard(icon: Icons.trending_up_rounded,
                label: AppStrings.get('avg_score', lang),
                value: '${(_avgScore * 100).round()}%',
                color: AppTheme.blue),
            const SizedBox(width: 10),
            _StatMiniCard(icon: Icons.check_circle_outline_rounded,
                label: AppStrings.get('passed_tests', lang),
                value: '$_passedTests', color: AppTheme.orange),
            const SizedBox(width: 10),
            _StatMiniCard(icon: Icons.access_time_rounded,
                label: AppStrings.get('total_tests', lang),
                value: '$_totalTests', color: AppTheme.blue),
          ],
        ),
        if (_recentResults.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildRecentResultsList(lang),
        ],
      ],
    );
  }

  Widget _buildRecentResultsList(String lang) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showAllResults = !_showAllResults),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: AppTheme.blue),
                const SizedBox(width: 10),
                Text(AppStrings.get('recent_results', lang),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppTheme.textP(context))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${_recentResults.length}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                          color: AppTheme.blue)),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _showAllResults ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textM(context)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: _buildResultItems(_recentResults.take(3).toList()),
          secondChild: _buildResultItems(_recentResults),
          crossFadeState: _showAllResults
              ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildResultItems(List<TestResult> results) {
    return Column(
      children: results.map((r) {
        final pct = (r.percentage * 100).round();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: r.isPassed
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Center(
                  child: Text('$pct%', style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: r.isPassed ? AppTheme.success : AppTheme.error)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.label, style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textP(context))),
                    Text('${r.correctAnswers}/${r.totalQuestions} · ${_fmtDate(r.date)}',
                        style: TextStyle(fontSize: 12,
                            color: AppTheme.textM(context))),
                  ],
                ),
              ),
              Icon(r.isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: r.isPassed ? AppTheme.success : AppTheme.error, size: 22),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _MenuActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final LinearGradient? gradient;
  final Color? iconColor;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _MenuActionCard({required this.icon, required this.title,
      required this.subtitle, this.gradient, this.iconColor,
      this.isHighlighted = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isHighlighted && gradient != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [BoxShadow(
                color: gradient!.colors.first.withValues(alpha: 0.3),
                blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  child: Icon(icon, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17,
                        fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85))),
                  ])),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.8), size: 24),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: AppTheme.isDark(context) ? null : [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(
                    color: (iconColor ?? AppTheme.blue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: Icon(icon, color: iconColor ?? AppTheme.blue, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textP(context))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13,
                      color: AppTheme.textM(context))),
                ])),
            Icon(Icons.chevron_right_rounded,
                color: iconColor ?? AppTheme.blue, size: 24),
          ],
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatMiniCard({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: AppTheme.isDark(context) ? null : [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10,
              color: AppTheme.textM(context)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
""")

# ═══════════════════════════════════════════════════════════════
# 3. TEST SCREEN — auto-advance on same row as Finish, consistent shapes
# ═══════════════════════════════════════════════════════════════
write('lib/screens/test_screen.dart', r"""import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class TestScreen extends StatefulWidget {
  final String title;
  final Future<List<Question>> Function() loadQuestions;
  final String testType;
  final String testLabel;
  final int timeLimitMinutes;

  const TestScreen({
    super.key,
    required this.title,
    required this.loadQuestions,
    required this.testType,
    required this.testLabel,
    this.timeLimitMinutes = 60,
  });

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with TickerProviderStateMixin {
  List<Question> _questions = [];
  int _currentIndex = 0;
  final Map<String, int> _selectedAnswers = {};
  final Set<String> _incorrectIds = {};
  late int _timeLeft;
  Timer? _timer;
  bool _loading = true;
  String? _error;
  late DateTime _startTime;
  late PageController _pageController;
  bool _autoAdvance = true;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.timeLimitMinutes * 60;
    _startTime = DateTime.now();
    _pageController = PageController();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final questions = await widget.loadQuestions();
      if (!mounted) return;
      setState(() { _questions = questions; _loading = false; });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) { timer.cancel(); _finishTest(); }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _selectAnswer(Question question, int optionId, String lang) {
    if (_selectedAnswers.containsKey(question.globalId)) return;

    final options = question.getOptions(lang);
    final selected = options.firstWhere((o) => o.id == optionId);

    setState(() {
      _selectedAnswers[question.globalId] = optionId;
      if (!selected.isCorrect) {
        _incorrectIds.add(question.globalId);
        StorageService.addErrorQuestion(question.globalId);
      }
    });

    if (_autoAdvance) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        final nextIndex = _findNextUnanswered(_currentIndex);
        if (nextIndex == -1) {
          _finishTest();
        } else {
          _goToQuestion(nextIndex);
        }
      });
    }
  }

  int _findNextUnanswered(int from) {
    for (int i = from + 1; i < _questions.length; i++) {
      if (!_selectedAnswers.containsKey(_questions[i].globalId)) return i;
    }
    for (int i = 0; i < from; i++) {
      if (!_selectedAnswers.containsKey(_questions[i].globalId)) return i;
    }
    return -1;
  }

  void _goToQuestion(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic);
  }

  void _finishTest() {
    _timer?.cancel();
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    final lang = context.read<LanguageProvider>().lang;
    final correctCount = _questions.where((q) {
      final selected = _selectedAnswers[q.globalId];
      if (selected == null) return false;
      final options = q.getOptions(lang);
      final correct = options.where((o) => o.isCorrect).firstOrNull;
      return correct != null && correct.id == selected;
    }).length;

    final answeredAll = _selectedAnswers.length >= _questions.length;
    final result = TestResult(
      type: widget.testType, label: widget.testLabel,
      totalQuestions: _questions.length, correctAnswers: correctCount,
      timeSpentSeconds: timeSpent, date: DateTime.now(),
      isCompleted: answeredAll,
    );

    StorageService.saveResult(result);

    if (!mounted) return;
    Navigator.pushReplacement(context, AppTheme.fadeRoute(ResultScreen(
      result: result,
      questions: _questions,
      selectedAnswers: _selectedAnswers,
      incorrectIds: _incorrectIds,
      testTitle: widget.title,
      retakeLoadQuestions: widget.loadQuestions,
      retakeTestType: widget.testType,
      retakeTestLabel: widget.testLabel,
      retakeTimeLimitMinutes: widget.timeLimitMinutes,
    )));
  }

  void _showExitDialog() {
    final lang = context.read<LanguageProvider>().lang;
    final s = (String k) => AppStrings.get(k, lang);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(s('exit_test')),
      content: Text(s('exit_test_msg')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(s('no_continue'))),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error, foregroundColor: Colors.white),
          child: Text(s('yes_exit')),
        ),
      ],
    ));
  }

  void _showFinishDialog() {
    final lang = context.read<LanguageProvider>().lang;
    final s = (String k) => AppStrings.get(k, lang);
    final unanswered = _questions.where(
        (q) => !_selectedAnswers.containsKey(q.globalId)).length;
    final answered = _questions.length - unanswered;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(s('finish_test')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _DialogStatRow(label: s('answered'), value: '$answered',
            color: AppTheme.success),
        _DialogStatRow(label: s('unanswered'), value: '$unanswered',
            color: AppTheme.orange),
        _DialogStatRow(label: s('total'), value: '${_questions.length}',
            color: AppTheme.blue),
        if (unanswered > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('$unanswered ${s('unanswered_warning')}',
                    style: const TextStyle(color: AppTheme.orange,
                        fontSize: 13))),
              ]),
            ),
          ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text(s('cancel'))),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); _finishTest(); },
            child: Text(s('yes_finish'))),
      ],
    ));
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final s = (String k) => AppStrings.get(k, lang);

    if (_loading) {
      return Scaffold(
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 60, height: 60,
              child: CircularProgressIndicator(color: AppTheme.blue,
                  strokeWidth: 3, backgroundColor: AppTheme.card(context))),
          const SizedBox(height: 20),
          Text(s('loading'),
              style: TextStyle(color: AppTheme.textS(context))),
        ])),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 16),
            Text('${s('error_prefix')}: $_error',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textS(context))),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context),
                child: Text(s('back'))),
          ]),
        )),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Text(s('no_questions'),
            style: TextStyle(color: AppTheme.textS(context)))),
      );
    }

    final progress = _selectedAnswers.length / _questions.length;
    final timerColor = _timeLeft < 60
        ? AppTheme.error
        : (_timeLeft < 300 ? AppTheme.orange : AppTheme.blue);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                border: Border(bottom: BorderSide(
                    color: AppTheme.border(context))),
              ),
              child: Column(children: [
                // Row 1: Timer + progress bar
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: timerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                          color: timerColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.timer_outlined, size: 16,
                          color: timerColor),
                      const SizedBox(width: 5),
                      Text(_formatTime(_timeLeft), style: TextStyle(
                          fontWeight: FontWeight.bold, color: timerColor,
                          fontSize: 15,
                          fontFeatures: const [
                            FontFeature.tabularFigures()])),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${_selectedAnswers.length}/${_questions.length}',
                            style: TextStyle(color: AppTheme.textS(context),
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.border(context),
                            valueColor: AlwaysStoppedAnimation(
                                AppTheme.blue),
                            minHeight: 4,
                          ),
                        ),
                      ])),
                ]),
                const SizedBox(height: 8),
                // Row 2: Auto-advance toggle + Finish + Close (all same row)
                Row(children: [
                  // Auto-advance toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _autoAdvance = !_autoAdvance),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _autoAdvance
                            ? AppTheme.blue.withValues(alpha: 0.12)
                            : AppTheme.surface(context),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: _autoAdvance
                              ? AppTheme.blue.withValues(alpha: 0.3)
                              : AppTheme.border(context),
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _autoAdvance
                                  ? Icons.skip_next_rounded
                                  : Icons.skip_next_outlined,
                              size: 16,
                              color: _autoAdvance
                                  ? AppTheme.blue
                                  : AppTheme.textM(context),
                            ),
                            const SizedBox(width: 5),
                            Text(s('auto_advance'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _autoAdvance
                                      ? AppTheme.blue
                                      : AppTheme.textM(context),
                                )),
                          ]),
                    ),
                  ),
                  const Spacer(),
                  // Finish button — same style as auto-advance chip
                  GestureDetector(
                    onTap: _showFinishDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.blue.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                            color: AppTheme.blue
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(s('finish'),
                          style: TextStyle(color: AppTheme.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button — same radius
                  GestureDetector(
                    onTap: _showExitDialog,
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.isDark(context)
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Icon(Icons.close, size: 16,
                          color: AppTheme.textM(context)),
                    ),
                  ),
                ]),
              ]),
            ),
            // Question numbers strip
            Container(
              height: 52,
              color: AppTheme.surface(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  final isAnswered = _selectedAnswers.containsKey(
                      q.globalId);
                  final isIncorrect = _incorrectIds.contains(q.globalId);
                  final isCurrent = index == _currentIndex;

                  Color bgColor; Color textColor; Border? border;

                  if (isCurrent) {
                    bgColor = AppTheme.blue;
                    textColor = Colors.white;
                  } else if (isIncorrect) {
                    bgColor = AppTheme.error.withValues(alpha: 0.2);
                    textColor = AppTheme.error;
                    border = Border.all(
                        color: AppTheme.error.withValues(alpha: 0.5));
                  } else if (isAnswered) {
                    bgColor = AppTheme.success.withValues(alpha: 0.2);
                    textColor = AppTheme.success;
                    border = Border.all(
                        color: AppTheme.success.withValues(alpha: 0.5));
                  } else {
                    bgColor = AppTheme.card(context);
                    textColor = AppTheme.textM(context);
                    border = Border.all(color: AppTheme.border(context));
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => _goToQuestion(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 36, height: 36, alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm),
                          border: border,
                        ),
                        child: Text('${index + 1}', style: TextStyle(
                            color: textColor, fontWeight: FontWeight.w700,
                            fontSize: 13)),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Question cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: _questions.length,
                onPageChanged: (index) =>
                    setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return _QuestionCard(
                    question: _questions[index],
                    questionIndex: index,
                    totalQuestions: _questions.length,
                    lang: lang,
                    selectedAnswer: _selectedAnswers[
                        _questions[index].globalId],
                    onSelect: (optionId) =>
                        _selectAnswer(_questions[index], optionId, lang),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final int questionIndex, totalQuestions;
  final String lang;
  final int? selectedAnswer;
  final ValueChanged<int> onSelect;

  const _QuestionCard({required this.question, required this.questionIndex,
      required this.totalQuestions, required this.lang,
      this.selectedAnswer, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = question.getOptions(lang);
    final s = (String k) => AppStrings.get(k, lang);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text('${s('question_n')} ${questionIndex + 1} / $totalQuestions',
                style: TextStyle(color: AppTheme.blue,
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 16),
          Text(question.getText(lang), style: TextStyle(fontSize: 17,
              fontWeight: FontWeight.w500, height: 1.5,
              color: AppTheme.textP(context))),
          if (question.mediaUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Image.asset(
                  'assets/tests-json/images/${question.mediaUrl}',
                  width: double.infinity, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ],
          const SizedBox(height: 24),
          ...List.generate(options.length, (i) {
            final option = options[i];
            final isSelected = selectedAnswer == option.id;
            final isAnswered = selectedAnswer != null;
            final isCorrect = option.isCorrect;

            Color bgColor = AppTheme.card(context);
            Color borderColor = AppTheme.border(context);
            Color textColor = AppTheme.textP(context);
            IconData? trailingIcon;
            Color? iconColor;

            if (isAnswered) {
              if (isCorrect) {
                bgColor = AppTheme.success.withValues(alpha: 0.12);
                borderColor = AppTheme.success.withValues(alpha: 0.4);
                textColor = AppTheme.success;
                trailingIcon = Icons.check_circle_rounded;
                iconColor = AppTheme.success;
              } else if (isSelected && !isCorrect) {
                bgColor = AppTheme.error.withValues(alpha: 0.12);
                borderColor = AppTheme.error.withValues(alpha: 0.4);
                textColor = AppTheme.error;
                trailingIcon = Icons.cancel_rounded;
                iconColor = AppTheme.error;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: isAnswered ? null : () => onSelect(option.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(children: [
                    Container(width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: isAnswered && isCorrect
                              ? AppTheme.success.withValues(alpha: 0.2)
                              : isAnswered && isSelected && !isCorrect
                                  ? AppTheme.error.withValues(alpha: 0.2)
                                  : AppTheme.border(context),
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm)),
                        child: Center(child: Text(
                            String.fromCharCode(65 + i),
                            style: TextStyle(color: textColor,
                                fontWeight: FontWeight.w700, fontSize: 14)))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(option.getText(lang),
                        style: TextStyle(fontSize: 15, color: textColor,
                            height: 1.4))),
                    if (trailingIcon != null)
                      Padding(padding: const EdgeInsets.only(left: 8),
                          child: Icon(trailingIcon, color: iconColor,
                              size: 22)),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DialogStatRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DialogStatRow({required this.label, required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AppTheme.textS(context))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10,
                  vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(value, style: TextStyle(
                  fontWeight: FontWeight.bold, color: color)),
            ),
          ]),
    );
  }
}
""")

# ═══════════════════════════════════════════════════════════════
# 4. RESULT SCREEN — consistent button shapes (all radiusMd), blue
# ═══════════════════════════════════════════════════════════════
write('lib/screens/result_screen.dart', r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import 'test_screen.dart';

class ResultScreen extends StatefulWidget {
  final TestResult result;
  final List<Question> questions;
  final Map<String, int> selectedAnswers;
  final Set<String> incorrectIds;
  final String? testTitle;
  final Future<List<Question>> Function()? retakeLoadQuestions;
  final String? retakeTestType;
  final String? retakeTestLabel;
  final int? retakeTimeLimitMinutes;

  const ResultScreen({
    super.key,
    required this.result,
    required this.questions,
    required this.selectedAnswers,
    required this.incorrectIds,
    this.testTitle,
    this.retakeLoadQuestions,
    this.retakeTestType,
    this.retakeTestLabel,
    this.retakeTimeLimitMinutes,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreAnimation = Tween<double>(begin: 0, end: widget.result.percentage)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final s = (String k) => AppStrings.get(k, lang);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Animated circle
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    final pct = (_scoreAnimation.value * 100).round();
                    return _ResultCircle(
                        percentage: pct,
                        progress: _scoreAnimation.value,
                        isPassed: widget.result.isPassed,
                        passedLabel: s('passed'),
                        failedLabel: s('not_passed'));
                  },
                ),
                const SizedBox(height: 24),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.result.isPassed
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: widget.result.isPassed
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    widget.result.isPassed ? s('congrats') : s('failed'),
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: widget.result.isPassed
                            ? AppTheme.success : AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.result.label,
                    style: TextStyle(fontSize: 14,
                        color: AppTheme.textM(context))),
                const SizedBox(height: 24),

                // Stats row
                Row(children: [
                  _StatCard(label: s('correct'),
                      value: '${widget.result.correctAnswers}',
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.success),
                  const SizedBox(width: 10),
                  _StatCard(label: s('incorrect'),
                      value: '${widget.incorrectIds.length}',
                      icon: Icons.cancel_rounded,
                      color: AppTheme.error),
                ]),
                const SizedBox(height: 12),

                // Time
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.cardDeco(context),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_outlined, size: 20,
                            color: AppTheme.blue),
                        const SizedBox(width: 8),
                        Text(
                          '${s('time_spent')}: '
                          '${widget.result.timeSpentSeconds ~/ 60} '
                          '${s('minutes')} '
                          '${widget.result.timeSpentSeconds % 60} '
                          '${s('seconds')}',
                          style: TextStyle(fontSize: 14,
                              color: AppTheme.textS(context)),
                        ),
                      ]),
                ),
                const SizedBox(height: 32),

                // Retake button
                if (widget.retakeLoadQuestions != null)
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd)),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(context,
                          AppTheme.fadeRoute(TestScreen(
                            title: widget.testTitle ?? widget.result.label,
                            loadQuestions: widget.retakeLoadQuestions!,
                            testType: widget.retakeTestType ?? widget.result.type,
                            testLabel: widget.retakeTestLabel ?? widget.result.label,
                            timeLimitMinutes: widget.retakeTimeLimitMinutes ?? 60,
                          )),
                        );
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(s('retake_test'),
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                if (widget.retakeLoadQuestions != null)
                  const SizedBox(height: 12),

                // Home button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.blue),
                      foregroundColor: AppTheme.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd)),
                    ),
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home_rounded),
                    label: Text(s('go_home'),
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCircle extends StatelessWidget {
  final int percentage;
  final double progress;
  final bool isPassed;
  final String passedLabel, failedLabel;

  const _ResultCircle({required this.percentage, required this.progress,
      required this.isPassed, required this.passedLabel,
      required this.failedLabel});

  @override
  Widget build(BuildContext context) {
    final color = isPassed ? AppTheme.success : AppTheme.error;
    return SizedBox(
      width: 170, height: 170,
      child: Stack(fit: StackFit.expand, children: [
        CircularProgressIndicator(value: progress, strokeWidth: 10,
            backgroundColor: AppTheme.border(context),
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$percentage%', style: TextStyle(fontSize: 40,
              fontWeight: FontWeight.bold, color: color)),
          Text(isPassed ? passedLabel : failedLabel,
              style: TextStyle(fontSize: 14, color: color)),
        ])),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppTheme.cardDeco(context),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 24,
              fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12,
              color: AppTheme.textM(context))),
        ]),
      ),
    );
  }
}
""")

# ═══════════════════════════════════════════════════════════════
# 5. REMAINING SCREENS — purple → blue references, consistent shapes
# ═══════════════════════════════════════════════════════════════

write('lib/screens/website_screen.dart', r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

class WebsiteScreen extends StatelessWidget {
  const WebsiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('nav_website', lang))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: const Icon(Icons.language_rounded, size: 40,
                    color: AppTheme.blue),
              ),
              const SizedBox(height: 24),
              Text('avtotestlar.uz', style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textP(context))),
              const SizedBox(height: 8),
              Text(AppStrings.get('visit_website', lang),
                  style: TextStyle(fontSize: 14,
                      color: AppTheme.textM(context)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('www.avtotestlar.uz'),
                          duration: Duration(seconds: 2)));
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(AppStrings.get('go_to_site', lang)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""")

write('lib/screens/profile_screen.dart', r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../services/app_strings.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  String _firstName = '';
  String _lastName = '';
  List<TestResult> _results = [];
  bool _loading = true;
  bool _showAllResults = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final (first, last) = await StorageService.getName();
    final results = await StorageService.getResults();
    if (!mounted) return;
    setState(() {
      _firstName = first; _lastName = last;
      _firstNameController.text = first;
      _lastNameController.text = last;
      _results = results; _loading = false;
    });
  }

  Future<void> _saveName() async {
    await StorageService.saveName(
        _firstNameController.text.trim(),
        _lastNameController.text.trim());
    setState(() {
      _firstName = _firstNameController.text.trim();
      _lastName = _lastNameController.text.trim();
    });
    if (mounted) {
      final lang = context.read<LanguageProvider>().lang;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.get('name_saved', lang)),
          duration: const Duration(seconds: 1)));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>().lang;
    final langProvider = context.watch<LanguageProvider>();
    final s = (String k) => AppStrings.get(k, lang);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(s('settings'))),
        body: Center(child: CircularProgressIndicator(
            color: AppTheme.blue)),
      );
    }

    final completedResults = _results.where((r) => r.isCompleted).toList();
    final totalTests = completedResults.length;
    final passedTests = completedResults.where((r) => r.isPassed).length;
    final avgScore = totalTests > 0
        ? (completedResults.fold<double>(0, (sum, r) => sum + r.percentage)
              / totalTests * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(s('settings')),
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded ? null : IconButton(
          icon: Container(padding: const EdgeInsets.all(6),
              decoration: AppTheme.glassDeco(context),
              child: const Icon(Icons.arrow_back_ios_new, size: 16)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDeco(context),
              child: Column(children: [
                Container(width: 72, height: 72,
                    decoration: BoxDecoration(
                        gradient: AppTheme.blueGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
                    child: Center(child: Text(
                        _firstName.isNotEmpty
                            ? _firstName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)))),
                const SizedBox(height: 12),
                if (_firstName.isNotEmpty || _lastName.isNotEmpty)
                  Text('$_firstName $_lastName',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textP(context))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                          labelText: s('first_name'), isDense: true),
                      style: TextStyle(color: AppTheme.textP(context)))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                          labelText: s('last_name'), isDense: true),
                      style: TextStyle(color: AppTheme.textP(context)))),
                ]),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _saveName,
                        child: Text(s('save')))),
              ]),
            ),
            const SizedBox(height: 16),

            // Language
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDeco(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s('language')} / Язык',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 16, color: AppTheme.textP(context))),
                  const SizedBox(height: 10),
                  ...LanguageProvider.languages.map((l) {
                    final selected = l['code'] == langProvider.lang;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        onTap: () =>
                            langProvider.setLanguage(l['code']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.blue.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd),
                            border: selected
                                ? Border.all(color: AppTheme.blue
                                    .withValues(alpha: 0.3))
                                : null,
                          ),
                          child: Row(children: [
                            Icon(selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? AppTheme.blue
                                    : AppTheme.textM(context),
                                size: 20),
                            const SizedBox(width: 10),
                            Text(l['label']!, style: TextStyle(
                                color: selected
                                    ? AppTheme.blue
                                    : AppTheme.textS(context),
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                          ]),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Theme toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDeco(context),
              child: Row(children: [
                Container(width: 42, height: 42,
                    decoration: BoxDecoration(
                        gradient: AppTheme.orangeGradient,
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd)),
                    child: Icon(context.watch<ThemeProvider>().isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                        color: Colors.white, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s('theme'), style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16,
                          color: AppTheme.textP(context))),
                      Text(context.watch<ThemeProvider>().isDark
                          ? s('dark_mode') : s('light_mode'),
                          style: TextStyle(color: AppTheme.textM(context),
                              fontSize: 13)),
                    ])),
                Switch(
                  value: context.watch<ThemeProvider>().isDark,
                  onChanged: (_) =>
                      context.read<ThemeProvider>().toggle(),
                  activeColor: AppTheme.blue,
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Statistics
            Text(s('statistics'), style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18,
                color: AppTheme.textP(context))),
            const SizedBox(height: 10),
            Row(children: [
              _MiniStat(label: s('total_tests'), value: '$totalTests',
                  color: AppTheme.blue),
              const SizedBox(width: 10),
              _MiniStat(label: s('passed_tests'), value: '$passedTests',
                  color: AppTheme.orange),
              const SizedBox(width: 10),
              _MiniStat(label: s('average'), value: '$avgScore%',
                  color: AppTheme.blue),
            ]),
            const SizedBox(height: 20),

            // Accordion results
            if (_results.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() =>
                    _showAllResults = !_showAllResults),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.card(context),
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusMd),
                    border: Border.all(
                        color: AppTheme.border(context)),
                  ),
                  child: Row(children: [
                    Icon(Icons.history_rounded, size: 20,
                        color: AppTheme.blue),
                    const SizedBox(width: 10),
                    Text(s('recent_results'), style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16,
                        color: AppTheme.textP(context))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.blue
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm),
                      ),
                      child: Text('${_results.length}',
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.blue)),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _showAllResults ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textM(context)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedCrossFade(
                firstChild: _buildResultItems(
                    _results.take(3).toList()),
                secondChild: _buildResultItems(
                    _results.take(20).toList()),
                crossFadeState: _showAllResults
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItems(List<TestResult> results) {
    return Column(
      children: results.map((r) {
        final pct = (r.percentage * 100).round();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: AppTheme.cardDeco(context),
          child: Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(
                    color: r.isPassed
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusMd)),
                child: Center(child: Text('$pct%',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: r.isPassed
                            ? AppTheme.success : AppTheme.error)))),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.label, style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textP(context))),
                  Text(
                    '${r.correctAnswers}/${r.totalQuestions} · ${_formatDate(r.date)}',
                    style: TextStyle(fontSize: 12,
                        color: AppTheme.textM(context))),
                ])),
            Icon(r.isPassed
                ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: r.isPassed ? AppTheme.success : AppTheme.error,
                size: 22),
          ]),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat({required this.label, required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppTheme.cardDeco(context),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11,
              color: AppTheme.textM(context)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
""")

write('lib/screens/topic_list_screen.dart', r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import 'test_screen.dart';

class TopicListScreen extends StatelessWidget {
  final bool embedded;
  const TopicListScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final topics = QuestionService.getTopics();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('topic_tests', lang)),
        automaticallyImplyLeading: !embedded,
        leading: embedded ? null : IconButton(
          icon: Container(padding: const EdgeInsets.all(6),
              decoration: AppTheme.glassDeco(context),
              child: const Icon(Icons.arrow_back_ios_new, size: 16)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                onTap: () {
                  Navigator.push(context, AppTheme.slideRoute(TestScreen(
                    title: topic.name,
                    loadQuestions: () =>
                        QuestionService.loadTopicQuestions(topic.filename),
                    testType: 'topic',
                    testLabel: topic.name,
                  )));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: AppTheme.cardDeco(context),
                  child: Row(children: [
                    Container(width: 42, height: 42,
                        decoration: BoxDecoration(
                            gradient: AppTheme.blueGradient,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd)),
                        child: Center(child: Text('${index + 1}',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)))),
                    const SizedBox(width: 14),
                    Expanded(child: Text(topic.name,
                        style: TextStyle(fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: AppTheme.textP(context)))),
                    Icon(Icons.chevron_right,
                        color: AppTheme.textM(context), size: 22),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
""")

write('lib/screens/variant_list_screen.dart', r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import 'test_screen.dart';

class VariantListScreen extends StatelessWidget {
  const VariantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final variants = QuestionService.getVariantFiles();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('variants', lang)),
        leading: IconButton(
          icon: Container(padding: const EdgeInsets.all(6),
              decoration: AppTheme.glassDeco(context),
              child: const Icon(Icons.arrow_back_ios_new, size: 16)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, crossAxisSpacing: 10,
          mainAxisSpacing: 10, childAspectRatio: 1),
        itemCount: variants.length,
        itemBuilder: (context, index) {
          final filename = variants[index];
          final variantNum = index + 1;

          return GestureDetector(
            onTap: () {
              final vLabel = '${AppStrings.get('variant', lang)} $variantNum';
              Navigator.push(context, AppTheme.slideRoute(TestScreen(
                title: vLabel,
                loadQuestions: () =>
                    QuestionService.loadVariantQuestions(filename),
                testType: 'variant',
                testLabel: vLabel,
                timeLimitMinutes: 25,
              )));
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.card(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                    color: AppTheme.orange.withValues(alpha: 0.15)),
              ),
              child: Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$variantNum',
                        style: const TextStyle(fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.orange)),
                    Text(AppStrings.get('variant', lang),
                        style: TextStyle(fontSize: 10,
                            color: AppTheme.textM(context))),
                  ])),
            ),
          );
        },
      ),
    );
  }
}
""")

write('lib/screens/practice_setup_screen.dart', r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import 'test_screen.dart';

class PracticeSetupScreen extends StatelessWidget {
  final bool embedded;
  const PracticeSetupScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final s = (String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(s('menu_test')),
        automaticallyImplyLeading: !embedded,
        leading: embedded ? null : IconButton(
          icon: Container(padding: const EdgeInsets.all(6),
              decoration: AppTheme.glassDeco(context),
              child: const Icon(Icons.arrow_back_ios_new, size: 16)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 40),
          Container(width: 80, height: 80,
              decoration: BoxDecoration(
                  gradient: AppTheme.blueGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  boxShadow: [BoxShadow(
                      color: AppTheme.blue.withValues(alpha: 0.3),
                      blurRadius: 20, offset: const Offset(0, 8))]),
              child: const Icon(Icons.play_circle_outline_rounded,
                  size: 40, color: Colors.white)),
          const SizedBox(height: 24),
          Text(s('choose_count'), style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textP(context))),
          const SizedBox(height: 8),
          Text(s('random_questions'),
              style: TextStyle(color: AppTheme.textM(context))),
          const SizedBox(height: 40),
          _PracticeOption(count: 20, timeMinutes: 25, lang: lang,
              gradient: AppTheme.blueGradient,
              onTap: () => _startPractice(context, 20, 25, lang)),
          const SizedBox(height: 16),
          _PracticeOption(count: 50, timeMinutes: 60, lang: lang,
              gradient: AppTheme.orangeGradient,
              onTap: () => _startPractice(context, 50, 60, lang)),
        ]),
      ),
    );
  }

  void _startPractice(BuildContext context, int count, int timeMinutes,
      String lang) {
    Navigator.pushReplacement(context, AppTheme.slideRoute(TestScreen(
      title: '$count ${AppStrings.get('n_questions', lang)}',
      loadQuestions: () =>
          QuestionService.loadPracticeQuestions(count: count),
      testType: 'practice',
      testLabel: '$count ${AppStrings.get('n_question_test', lang)}',
      timeLimitMinutes: timeMinutes,
    )));
  }
}

class _PracticeOption extends StatefulWidget {
  final int count, timeMinutes;
  final String lang;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PracticeOption({required this.count, required this.timeMinutes,
      required this.lang, required this.gradient, required this.onTap});

  @override
  State<_PracticeOption> createState() => _PracticeOptionState();
}

class _PracticeOptionState extends State<_PracticeOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: [BoxShadow(
                        color: widget.gradient.colors.first
                            .withValues(alpha: 0.3),
                        blurRadius: 12, offset: const Offset(0, 4))]),
                child: Center(child: Text('${widget.count}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 16),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.count} ${AppStrings.get('n_questions', widget.lang)}',
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textP(context))),
                  Text('${widget.timeMinutes} ${AppStrings.get('n_minutes', widget.lang)}',
                      style: TextStyle(
                          color: AppTheme.textM(context))),
                ])),
            Container(width: 44, height: 44,
                decoration: BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                child: const Icon(Icons.play_arrow_rounded,
                    color: AppTheme.blue, size: 28)),
          ]),
        ),
      ),
    );
  }
}
""")

write('lib/screens/errors_screen.dart', r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/storage_service.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';

class ErrorsScreen extends StatefulWidget {
  final bool embedded;
  const ErrorsScreen({super.key, this.embedded = false});

  @override
  State<ErrorsScreen> createState() => _ErrorsScreenState();
}

class _ErrorsScreenState extends State<ErrorsScreen> {
  List<Question> _errorQuestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  Future<void> _loadErrors() async {
    final errorIds = await StorageService.getErrorQuestions();
    if (errorIds.isEmpty) {
      setState(() => _loading = false); return;
    }
    final allQuestions = await QuestionService.loadAllQuestions();
    final errors = allQuestions
        .where((q) => errorIds.contains(q.globalId)).toList();
    if (!mounted) return;
    setState(() { _errorQuestions = errors; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final s = (String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(s('my_errors')),
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded ? null : IconButton(
          icon: Container(padding: const EdgeInsets.all(6),
              decoration: AppTheme.glassDeco(context),
              child: const Icon(Icons.arrow_back_ios_new, size: 16)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_errorQuestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(s('clear_errors_title')),
                      content: Text(s('clear_errors_msg')),
                      actions: [
                        TextButton(onPressed: () =>
                            Navigator.pop(ctx, false),
                            child: Text(s('no'))),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                              foregroundColor: Colors.white),
                          child: Text(s('yes')),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await StorageService.clearErrorQuestions();
                    setState(() => _errorQuestions.clear());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline, size: 16,
                            color: AppTheme.error),
                        const SizedBox(width: 4),
                        Text(s('clear'), style: const TextStyle(
                            color: AppTheme.error, fontSize: 13,
                            fontWeight: FontWeight.w600)),
                      ]),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(
              color: AppTheme.blue))
          : _errorQuestions.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 80, height: 80,
                        decoration: BoxDecoration(
                            color: AppTheme.success
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusXl)),
                        child: const Icon(Icons.check_circle_outline,
                            size: 40, color: AppTheme.success)),
                    const SizedBox(height: 20),
                    Text(s('no_errors'), style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textP(context))),
                    const SizedBox(height: 8),
                    Text(s('no_errors_sub'),
                        style: TextStyle(
                            color: AppTheme.textM(context))),
                  ]))
              : Column(children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                          AppTheme.radiusMd),
                      border: Border.all(
                          color: AppTheme.error
                              .withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, size: 20,
                          color: AppTheme.error),
                      const SizedBox(width: 8),
                      Text(
                        '${_errorQuestions.length} ${s('total_errors')}',
                        style: const TextStyle(color: AppTheme.error,
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _errorQuestions.length,
                      itemBuilder: (context, index) {
                        final q = _errorQuestions[index];
                        return _ErrorQuestionCard(
                            index: index, question: q, lang: lang);
                      },
                    ),
                  ),
                ]),
    );
  }
}

class _ErrorQuestionCard extends StatefulWidget {
  final int index;
  final Question question;
  final String lang;

  const _ErrorQuestionCard({required this.index,
      required this.question, required this.lang});

  @override
  State<_ErrorQuestionCard> createState() => _ErrorQuestionCardState();
}

class _ErrorQuestionCardState extends State<_ErrorQuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final options = widget.question.getOptions(widget.lang);
    final correct = options.where((o) => o.isCorrect).firstOrNull;
    final s = (String k) => AppStrings.get(k, widget.lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDeco(context,
        b: Border.all(color: AppTheme.error.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm)),
                    child: Center(child: Text('${widget.index + 1}',
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.error)))),
                const SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.question.getText(widget.lang),
                          style: TextStyle(fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: AppTheme.textP(context)),
                          maxLines: _expanded ? null : 3,
                          overflow: _expanded
                              ? null : TextOverflow.ellipsis),
                      if (correct != null && !_expanded) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.success
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm),
                          ),
                          child: Text(
                            '${s('correct_answer')}: ${correct.getText(widget.lang)}',
                            style: const TextStyle(
                                color: AppTheme.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ])),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.keyboard_arrow_down,
                      color: AppTheme.textM(context), size: 22),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppTheme.border(context)),
                  const SizedBox(height: 6),
                  Text('${s('all_options')}:',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textM(context))),
                  const SizedBox(height: 8),
                  ...List.generate(options.length, (i) {
                    final opt = options[i];
                    final isCorrectOpt = opt.isCorrect;
                    Color optBg = Colors.transparent;
                    Color optBorder = AppTheme.border(context);
                    Color optText = AppTheme.textS(context);
                    IconData? optIcon;

                    if (isCorrectOpt) {
                      optBg = AppTheme.success.withValues(alpha: 0.08);
                      optBorder = AppTheme.success
                          .withValues(alpha: 0.3);
                      optText = AppTheme.success;
                      optIcon = Icons.check_circle_rounded;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: optBg,
                        borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm),
                        border: Border.all(color: optBorder),
                      ),
                      child: Row(children: [
                        Text('${String.fromCharCode(65 + i)}. ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: optText, fontSize: 13)),
                        Expanded(child: Text(
                            opt.getText(widget.lang),
                            style: TextStyle(fontSize: 13,
                                color: optText))),
                        if (optIcon != null)
                          Icon(optIcon, size: 18, color: optText),
                      ]),
                    );
                  }),
                ]),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ]),
    );
  }
}
""")

# Update main_shell to use blue instead of purple
write('lib/screens/main_shell.dart', r"""import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'topic_list_screen.dart';
import 'website_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    TopicListScreen(embedded: true),
    WebsiteScreen(),
    ProfileScreen(embedded: true),
  ];

  void switchTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final selectedColor = AppTheme.primary(context);
    final unselectedColor = AppTheme.textM(context);
    final dark = AppTheme.isDark(context);
    final navBg = dark ? AppTheme.surfaceBg : Colors.white;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: AppTheme.border(context))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: AppStrings.get('nav_home', lang),
                  selected: _currentIndex == 0,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => switchTab(0),
                ),
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: AppStrings.get('nav_topics', lang),
                  selected: _currentIndex == 1,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => switchTab(1),
                ),
                _NavItem(
                  icon: Icons.language_rounded,
                  label: AppStrings.get('nav_website', lang),
                  selected: _currentIndex == 2,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => switchTab(2),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: AppStrings.get('nav_settings', lang),
                  selected: _currentIndex == 3,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => switchTab(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 24 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
""")

print('\n=== All files regenerated ===')
