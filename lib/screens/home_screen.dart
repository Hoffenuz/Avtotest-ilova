import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../services/test_results_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/update_banner.dart';
import 'difficult_questions_screen.dart';
import 'errors_screen.dart';
import 'main_shell.dart';
import 'pro_screen.dart';
import 'real_exam_screen.dart';
import 'topic_list_screen.dart';
import 'variant_list_screen.dart';

/// Bosh ekran: yuqorida o'qiladigan qism (sarlavha, tayyorgarlik, tezkor
/// bo'limlar, so'nggi natijalar), pastda — bosh barmoq yetadigan joyda —
/// doim ko'rinadigan amallar.
///
/// "Test ishlash" — ekrandagi yagona to'la tugma: ilovani ochgan odamning
/// ko'zi unga tushadi va ikki bosishda test boshlanadi (shu tugma →
/// "Testni boshlash").
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  int _totalTests = 0;
  List<TestResult> _recentResults = [];
  bool _showAllResults = false;

  /// Average of the last [_readinessWindow] finished tests — how the user is
  /// doing now, not what they scored on day one.
  double _readiness = 0;
  int _readinessTests = 0;
  static const _readinessWindow = 10;

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
    final recent = completed.take(_readinessWindow).toList();
    setState(() {
      _totalTests = completed.length;
      _recentResults = results;
      _readinessTests = recent.length;
      _readiness = recent.isEmpty
          ? 0
          : recent.fold<double>(0, (sum, r) => sum + r.percentage) /
                recent.length;
    });
  }

  void _push(Widget screen, {bool fade = false}) {
    Navigator.push(
      context,
      fade ? AppTheme.fadeRoute(screen) : AppTheme.slideRoute(screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>().lang;
    String s(String key) => AppStrings.get(key, lang);

    final isLoggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    final isPro = context.select<SubscriptionProvider, bool>(
      (sub) => sub.isPro,
    );
    // `isDeniedForSure`, not `!isPro`: before the access RPC answers, `isPro`
    // is false for everyone, and a subscriber would watch PRO badges appear
    // on their own content for a frame and then vanish.
    final isDeniedForSure = context.select<SubscriptionProvider, bool>(
      (sub) => sub.isDeniedForSure,
    );
    final needsPro = !isLoggedIn || isDeniedForSure;

    return Scaffold(
      body: Column(
        children: [
          BrandHeader(onPro: () => _push(const ProScreen())),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStats,
              color: AppTheme.brandAccent(context),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                children: [
                  // A user who never opens Settings would otherwise keep
                  // practising on an outdated question bank forever.
                  const UpdateBanner(),
                  _Hero(
                    lang: lang,
                    completedTests: _totalTests,
                    readiness: _readiness,
                    readinessTests: _readinessTests,
                  ),
                  const SizedBox(height: 20),
                  _QuickRow(
                    tiles: [
                      _QuickTileData(
                        icon: Icons.timer_outlined,
                        title: s('real_exam'),
                        onTap: () => _push(const RealExamScreen(), fade: true),
                      ),
                      _QuickTileData(
                        icon: Icons.psychology_outlined,
                        title: s('section_errors_drill'),
                        pro: needsPro,
                        onTap: () => _push(const ErrorsScreen()),
                      ),
                      _QuickTileData(
                        icon: Icons.warning_amber_rounded,
                        title: s('difficult_questions'),
                        pro: needsPro,
                        onTap: () => _push(const DifficultQuestionsScreen()),
                      ),
                    ],
                  ),
                  if (_recentResults.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildRecentResults(lang),
                  ],
                  if (needsPro) ...[
                    const SizedBox(height: 20),
                    ProUpsellCard(
                      title: s('pro_card_title'),
                      description: s('pro_card_desc').replaceAll(
                        '{variants}',
                        AppStrings.variantsPhrase(
                          QuestionService.variantCount,
                          lang,
                        ),
                      ),
                      action: s('get_pro'),
                      onTap: () => _push(const ProScreen()),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // THE ACTIONS SIT WHERE THE THUMB IS. At the top of a tall phone the
          // three buttons were a stretch to reach; here they are always on
          // screen, right above the tab bar, and "Test ishlash" is the one
          // filled button so the eye lands on it first — for PRO users too.
          _ActionPanel(
            testLabel: s('home_btn_test'),
            variantsLabel: s('home_btn_variants'),
            topicsLabel: s('home_btn_topics'),
            isPro: isPro,
            topicsNeedPro: needsPro,
            // Switches to the practice tab rather than pushing a second copy
            // of the same screen on top of it.
            onTest: () => context
                .findAncestorStateOfType<MainShellState>()
                ?.switchTab(MainShellState.practiceTab),
            onVariants: () => _push(const VariantListScreen()),
            onTopics: () => _push(const TopicListScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResults(String lang) {
    String s(String key) => AppStrings.get(key, lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s('recent_results'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textP(context),
          ),
        ),
        const SizedBox(height: 10),
        // Capped: the history holds up to 100 entries and they all sit in one
        // Column, so expanding used to build every one of them.
        for (final r in _recentResults.take(_showAllResults ? 20 : 3))
          _ResultRow(result: r, lang: lang),
        if (_recentResults.length > 3)
          Center(
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _showAllResults = !_showAllResults),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.brandAccent(context),
                minimumSize: const Size(0, 44),
              ),
              icon: Icon(
                _showAllResults
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
              label: Text(
                _showAllResults
                    ? s('show_less')
                    : '${s('show_all')} (${_recentResults.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

/// Sarlavha va tayyorgarlik — sodda: bitta sarlavha, bitta ko'rsatkich.
/// Test ishlamagan foydalanuvchiga nol emas, imtihon qoidasi ko'rsatiladi.
class _Hero extends StatelessWidget {
  final String lang;
  final int completedTests;
  final double readiness;
  final int readinessTests;

  const _Hero({
    required this.lang,
    required this.completedTests,
    required this.readiness,
    required this.readinessTests,
  });

  @override
  Widget build(BuildContext context) {
    String s(String key) => AppStrings.get(key, lang);
    final dark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Badge(text: s('home_badge')),
        const SizedBox(height: 12),
        Text(
          s('hero_title'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.2,
            color: dark ? AppTheme.textPrimary : AppTheme.ink,
          ),
        ),
        const SizedBox(height: 14),
        // Before the first test: what the exam is, in the site's three cells.
        // After it: how close the user is to passing it.
        if (completedTests == 0)
          StatCells(
            cells: [
              ('20', s('stat_questions')),
              ('25', s('stat_minutes')),
              ('90%', s('stat_pass')),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.hairline(context)),
            ),
            child: _Readiness(
              title: s('readiness_title'),
              subtitle: s('readiness_sub').replaceAll('{n}', '$readinessTests'),
              value: readiness,
            ),
          ),
      ],
    );
  }
}

/// Foiz, chiziq va 90% belgisi — "o'tdi" shu yerdan boshlanadi. Yashil faqat
/// chegaradan o'tganda: rang holatni bildiradi, bezak emas.
class _Readiness extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;

  const _Readiness({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    final passing = value >= 0.9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textP(context),
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: passing ? AppTheme.success : AppTheme.textP(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) => Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppTheme.hairline(context),
                  color: passing
                      ? AppTheme.success
                      : AppTheme.brandFill(context),
                ),
              ),
              Positioned(
                left: box.maxWidth * 0.9 - 1,
                top: -3,
                child: Container(
                  width: 2,
                  height: 14,
                  color: AppTheme.textP(context).withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12.5, color: AppTheme.mutedText(context)),
        ),
      ],
    );
  }
}

class _QuickTileData {
  final IconData icon;
  final String title;
  final bool pro;
  final VoidCallback onTap;
  const _QuickTileData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.pro = false,
  });
}

/// Uchta tezkor bo'lim bitta qatorda — saytdagi QUICK_ITEMS bilan bir xil.
class _QuickRow extends StatelessWidget {
  final List<_QuickTileData> tiles;
  const _QuickRow({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Material(
                      color: AppTheme.card(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        side: BorderSide(color: AppTheme.hairline(context)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(onTap: tiles[i].onTap),
                    ),
                  ),
                  IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : AppTheme.ink.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                            child: Icon(
                              tiles[i].icon,
                              size: 22,
                              color: dark ? Colors.white : AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tiles[i].title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color: AppTheme.textP(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (tiles[i].pro)
                    const Positioned(right: -4, top: -8, child: ProTag()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Qo'l yetadigan joydagi amallar: to'la siyoh "Test ishlash" va uning
/// ostida yonma-yon ikkilamchi "Variantlar" | "Mavzular".
class _ActionPanel extends StatelessWidget {
  final String testLabel;
  final String variantsLabel;
  final String topicsLabel;
  final bool isPro;
  final bool topicsNeedPro;
  final VoidCallback onTest;
  final VoidCallback onVariants;
  final VoidCallback onTopics;

  const _ActionPanel({
    required this.testLabel,
    required this.variantsLabel,
    required this.topicsLabel,
    required this.isPro,
    required this.topicsNeedPro,
    required this.onTest,
    required this.onVariants,
    required this.onTopics,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final crown = CrownIcon(
      size: 20,
      color: dark ? AppTheme.proBorder : AppTheme.proIcon,
    );
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppTheme.scaffoldBg : AppTheme.lightScaffoldBg,
        border: Border(top: BorderSide(color: AppTheme.hairline(context))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandButton(
            label: testLabel,
            icon: const Icon(Icons.play_arrow_rounded),
            minHeight: 58,
            onPressed: onTest,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BrandButton(
                  label: variantsLabel,
                  icon: isPro ? crown : const Icon(Icons.grid_view_rounded),
                  kind: BrandButtonKind.secondary,
                  minHeight: 48,
                  dense: true,
                  onPressed: onVariants,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BrandButton(
                  label: topicsLabel,
                  icon: isPro ? crown : const Icon(Icons.menu_book_rounded),
                  kind: BrandButtonKind.secondary,
                  minHeight: 48,
                  dense: true,
                  proTag: topicsNeedPro,
                  onPressed: onTopics,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Saytdagi "2026 YHQ savollari" belgisi: chegarali kichik yorliq, ko'k nuqta.
class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.blue600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final TestResult result;
  final String lang;
  const _ResultRow({required this.result, required this.lang});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final pct = (r.percentage * 100).round();
    final color = r.isPassed ? AppTheme.success : AppTheme.error;
    final d = r.date;
    final date =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '$pct%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
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
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
                Text(
                  '${r.correctAnswers}/${r.totalQuestions} · $date',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            r.isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 22,
          ),
        ],
      ),
    );
  }
}
