import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_strings.dart';
import '../services/test_results_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/telegram_group_banner.dart';
import '../widgets/update_banner.dart';
import 'errors_screen.dart';
import 'main_shell.dart';
import 'real_exam_screen.dart';
import 'road_signs_screen.dart';
import 'saved_questions_screen.dart';
import 'topic_list_screen.dart';
import 'variant_list_screen.dart';

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
    // The home tab is kept alive inside an IndexedStack, so returning from a
    // finished test never re-ran initState and the statistics stayed stale
    // until the user pulled to refresh.
    TestResultsService.revision.addListener(_loadStats);
  }

  @override
  void dispose() {
    TestResultsService.revision.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadStats() async {
    final results = await TestResultsService.getPracticeResults();
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
              parent: AlwaysScrollableScrollPhysics(),
            ),
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
                      // Also on the home screen, not only in Settings: a user
                      // who never opens Settings would otherwise keep
                      // practising on an outdated question bank forever.
                      const UpdateBanner(),
                      _buildHeroCard(lang),
                      const SizedBox(height: 20),
                      _buildMenuCards(lang),
                      const SizedBox(height: 24),
                      _buildQuickActions(lang),
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverToBoxAdapter(child: TelegramGroupBanner()),
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
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          const Expanded(child: AppHeaderLogo(height: 30)),
          GestureDetector(
            onTap: () => context
                .findAncestorStateOfType<MainShellState>()
                ?.switchTab(MainShellState.profileTab),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: AppTheme.textS(context),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.get('hero_title', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textP(context),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.get('hero_subtitle', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textM(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCards(String lang) {
    final isLoggedIn = context.select<AuthProvider, bool>(
      (auth) => auth.isLoggedIn,
    );
    // `isDeniedForSure`, not `!isPro`: before the access RPC answers, `isPro`
    // is false for everyone, and a subscriber would watch PRO badges appear
    // on their own content for a frame and then vanish. `select` rather than
    // `watch` — this only needs to rebuild when the *verdict* flips, not on
    // every loading-state notify a background refresh fires.
    final isDeniedForSure = context.select<SubscriptionProvider, bool>(
      (sub) => sub.isDeniedForSure,
    );
    final needsPro = !isLoggedIn || isDeniedForSure;

    return Column(
      children: [
        _MenuActionCard(
          icon: Icons.play_circle_filled_rounded,
          title: AppStrings.get('menu_test', lang),
          subtitle: AppStrings.get('menu_test_sub', lang),
          gradient: AppTheme.blueGradient,
          isHighlighted: true,
          // Switches to the practice tab rather than pushing a second copy of
          // the same screen on top of it.
          onTap: () => context
              .findAncestorStateOfType<MainShellState>()
              ?.switchTab(MainShellState.practiceTab),
        ),
        const SizedBox(height: 12),
        _MenuActionCard(
          icon: Icons.quiz_rounded,
          title: AppStrings.get('menu_variants', lang),
          // Not "PRO required" any more — the first five tickets are open to
          // everyone, and saying otherwise turned people away from something
          // they could already use.
          subtitle: needsPro
              ? AppStrings.get('free_variants_short', lang)
              : AppStrings.get('menu_variants_sub', lang),
          iconColor: AppTheme.blue,
          showProBadge: needsPro,
          onTap: () => Navigator.push(
            context,
            AppTheme.slideRoute(const VariantListScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _MenuActionCard(
          icon: Icons.menu_book_rounded,
          title: AppStrings.get('menu_topics', lang),
          subtitle: needsPro
              ? AppStrings.get('free_topics_short', lang)
              : AppStrings.get('menu_topics_sub', lang),
          iconColor: AppTheme.orange,
          showProBadge: needsPro,
          onTap: () => Navigator.push(
            context,
            AppTheme.slideRoute(const TopicListScreen()),
          ),
        ),
      ],
    );
  }

  /// Second row of entry points, under the three big cards.
  ///
  /// These are the things people come back for once they have started
  /// studying — the exam rehearsal and their own mistakes — and they were
  /// buried one tab and one scroll away in Sections. Compact tiles rather than
  /// more full-width cards, so the results below stay above the fold.
  Widget _buildQuickActions(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppStrings.get('quick_actions', lang),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textP(context),
            ),
          ),
        ),
        Row(
          children: [
            _QuickTile(
              icon: Icons.assignment_turned_in_rounded,
              color: AppTheme.error,
              title: AppStrings.get('real_exam', lang),
              subtitle: AppStrings.get('quick_real_exam', lang),
              onTap: () => Navigator.push(
                context,
                AppTheme.fadeRoute(const RealExamScreen()),
              ),
            ),
            const SizedBox(width: 12),
            _QuickTile(
              icon: Icons.error_outline_rounded,
              color: AppTheme.orange,
              title: AppStrings.get('my_errors', lang),
              subtitle: AppStrings.get('quick_errors', lang),
              onTap: () => Navigator.push(
                context,
                AppTheme.slideRoute(const ErrorsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickTile(
              icon: Icons.bookmark_rounded,
              color: AppTheme.blue,
              title: AppStrings.get('saved_tests', lang),
              subtitle: AppStrings.get('quick_saved', lang),
              onTap: () => Navigator.push(
                context,
                AppTheme.slideRoute(const SavedQuestionsScreen()),
              ),
            ),
            const SizedBox(width: 12),
            _QuickTile(
              icon: Icons.signpost_rounded,
              color: AppTheme.success,
              title: AppStrings.get('road_signs', lang),
              subtitle: AppStrings.get('quick_signs', lang),
              onTap: () => Navigator.push(
                context,
                AppTheme.slideRoute(const RoadSignsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsSection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('your_results', lang),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textP(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatMiniCard(
              icon: Icons.trending_up_rounded,
              label: AppStrings.get('avg_score', lang),
              value: '${(_avgScore * 100).round()}%',
              color: AppTheme.blue,
            ),
            const SizedBox(width: 10),
            _StatMiniCard(
              icon: Icons.check_circle_outline_rounded,
              label: AppStrings.get('passed_tests', lang),
              value: '$_passedTests',
              color: AppTheme.orange,
            ),
            const SizedBox(width: 10),
            _StatMiniCard(
              icon: Icons.access_time_rounded,
              label: AppStrings.get('total_tests', lang),
              value: '$_totalTests',
              color: AppTheme.blue,
            ),
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
                const Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: AppTheme.blue,
                ),
                const SizedBox(width: 10),
                Text(
                  AppStrings.get('recent_results', lang),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_recentResults.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blue,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _showAllResults
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textM(context),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Capped: the history holds up to 100 entries and they all sit in one
        // Column inside a sliver, so expanding used to build every one of them.
        _buildResultItems(
          _recentResults.take(_showAllResults ? 20 : 3).toList(),
          lang,
        ),
      ],
    );
  }

  Widget _buildResultItems(List<TestResult> results, String lang) {
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: r.isPassed
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Center(
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: r.isPassed ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.displayLabel(lang),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textP(context),
                      ),
                    ),
                    Text(
                      '${r.correctAnswers}/${r.totalQuestions} · ${_fmtDate(r.date)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textM(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                r.isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: r.isPassed ? AppTheme.success : AppTheme.error,
                size: 22,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// Half-width entry point: icon, name, one line of what it is.
class _QuickTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textP(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: AppTheme.textM(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final LinearGradient? gradient;
  final Color? iconColor;
  final bool isHighlighted;
  final bool showProBadge;
  final VoidCallback onTap;

  const _MenuActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.gradient,
    this.iconColor,
    this.isHighlighted = false,
    this.showProBadge = false,
    required this.onTap,
  });

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
            boxShadow: [
              BoxShadow(
                color: gradient!.colors.first.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 24,
              ),
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
          boxShadow: AppTheme.isDark(context)
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.blue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: iconColor ?? AppTheme.blue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textP(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textM(context),
                    ),
                  ),
                ],
              ),
            ),
            if (showProBadge)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              color: iconColor ?? AppTheme.blue,
              size: 24,
            ),
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

  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: AppTheme.isDark(context)
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: AppTheme.textM(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
