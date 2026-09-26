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
import '../widgets/telegram_group_banner.dart';
import '../widgets/update_banner.dart';
import 'difficult_questions_screen.dart';
import 'errors_screen.dart';
import 'main_shell.dart';
import 'pro_screen.dart';
import 'real_exam_screen.dart';
import 'topic_list_screen.dart';
import 'variant_list_screen.dart';

/// Bosh ekran — saytning bosh sahifasi tuzilishida (src/pages/Home.tsx):
/// siyoh header, sarlavha, uchta asosiy tugma, uchta tezkor bo'lim, oxirida
/// bitta tinch PRO taklifi.
///
/// "Test ishlash" eng katta va to'la siyoh: ilovani ochgan odam ikki bosishda
/// testni boshlaydi (shu tugma → "Testni boshlash"). Sozlamalar tishli
/// g'ildiragi va "Saqlangan / Yo'l belgilari" plitkalari olib tashlandi —
/// ular pastki menyuda va Bo'limlarda bor, bu yerda takror edi.
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
    final isPro = context.select<SubscriptionProvider, bool>((sub) => sub.isPro);
    // `isDeniedForSure`, not `!isPro`: before the access RPC answers, `isPro`
    // is false for everyone, and a subscriber would watch PRO badges appear
    // on their own content for a frame and then vanish.
    final isDeniedForSure = context.select<SubscriptionProvider, bool>(
      (sub) => sub.isDeniedForSure,
    );
    final needsPro = !isLoggedIn || isDeniedForSure;
    final dark = AppTheme.isDark(context);

    const crown = CrownIcon(size: 22, color: AppTheme.proBorder);

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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  // A user who never opens Settings would otherwise keep
                  // practising on an outdated question bank forever.
                  const UpdateBanner(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Badge(text: s('home_badge')),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s('home_title'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.2,
                      color: dark ? AppTheme.textPrimary : AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 20),
                  BrandButton(
                    label: s('home_btn_test'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    minHeight: 60,
                    // Switches to the practice tab rather than pushing a
                    // second copy of the same screen on top of it.
                    onPressed: () => context
                        .findAncestorStateOfType<MainShellState>()
                        ?.switchTab(MainShellState.practiceTab),
                  ),
                  const SizedBox(height: 12),
                  // PRO egasida bu ikkisi ham to'la siyoh, ikonka o'rnida
                  // oltin toj — aynan shu imkoniyatlar uchun to'lagan.
                  BrandButton(
                    label: s('home_btn_variants'),
                    icon: isPro ? crown : const Icon(Icons.grid_view_rounded),
                    kind: isPro
                        ? BrandButtonKind.primary
                        : BrandButtonKind.secondary,
                    minHeight: 60,
                    onPressed: () => _push(const VariantListScreen()),
                  ),
                  const SizedBox(height: 12),
                  BrandButton(
                    label: s('home_btn_topics'),
                    icon: isPro ? crown : const Icon(Icons.menu_book_rounded),
                    kind: isPro
                        ? BrandButtonKind.primary
                        : BrandButtonKind.secondary,
                    minHeight: 60,
                    proTag: needsPro,
                    onPressed: () => _push(const TopicListScreen()),
                  ),
                  const SizedBox(height: 28),
                  SectionTile(
                    icon: Icons.timer_outlined,
                    title: s('real_exam'),
                    onTap: () => _push(const RealExamScreen(), fade: true),
                  ),
                  const SizedBox(height: 10),
                  SectionTile(
                    icon: Icons.psychology_outlined,
                    title: s('section_errors_drill'),
                    corner: needsPro ? const ProTag() : null,
                    onTap: () => _push(const ErrorsScreen()),
                  ),
                  const SizedBox(height: 10),
                  SectionTile(
                    icon: Icons.warning_amber_rounded,
                    title: s('difficult_questions'),
                    corner: needsPro ? const ProTag() : null,
                    onTap: () => _push(const DifficultQuestionsScreen()),
                  ),
                  // Nothing to show before the first test — a row of zeros
                  // only tells a new user what they have not done yet.
                  if (_recentResults.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildResults(lang),
                  ],
                  if (needsPro) ...[
                    const SizedBox(height: 24),
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
                  const SizedBox(height: 20),
                  const TelegramGroupBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(String lang) {
    String s(String key) => AppStrings.get(key, lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s('your_results'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textP(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.hairline(context)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _Stat(value: '${(_avgScore * 100).round()}%', label: s('avg_score')),
                VerticalDivider(width: 1, color: AppTheme.hairline(context)),
                _Stat(value: '$_passedTests', label: s('passed_tests')),
                VerticalDivider(width: 1, color: AppTheme.hairline(context)),
                _Stat(value: '$_totalTests', label: s('total_tests')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
                '${s('recent_results')} (${_recentResults.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
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

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textP(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.mutedText(context)),
            ),
          ],
        ),
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
