import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/update_banner.dart';
import '../widgets/readiness_widgets.dart';
import 'difficult_questions_screen.dart';
import 'errors_screen.dart';
import 'main_shell.dart';
import 'pro_screen.dart';
import 'real_exam_screen.dart';
import 'profile_screen.dart';
import 'topic_list_screen.dart';
import 'variant_list_screen.dart';

/// Bosh ekran — saytning bosh sahifasi (src/pages/Home.tsx) bilan bir xil
/// tartibda: nishon, sarlavha, qisqa izoh, uchta katta tugma
/// (MainTestButtons), keyin tezkor bo'limlar (QUICK_ITEMS). Ortiqcha narsa
/// yo'q — natijalar Sozlamalar → Natijalarim da.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

    void push(Widget screen, {bool fade = false}) => Navigator.push(
      context,
      fade ? AppTheme.fadeRoute(screen) : AppTheme.slideRoute(screen),
    );

    // "Test ishlash" tab — also from the results page opened on top.
    void startTest() {
      Navigator.of(context).popUntil((r) => r.isFirst);
      context.findAncestorStateOfType<MainShellState>()?.switchTab(
        MainShellState.practiceTab,
      );
    }

    // A subscriber's secondary buttons are filled with a gold crown, as on
    // the site: everything behind them is already theirs.
    final secondaryKind = isPro
        ? BrandButtonKind.primary
        : BrandButtonKind.secondary;
    const crown = CrownIcon(size: 22, color: AppTheme.proBorder);

    return Scaffold(
      body: Column(
        children: [
          BrandHeader(
            onPro: () => push(const ProScreen()),
            actions: const [LanguageMenu()],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
                children: [
                  // THE HERO FILLS THE FIRST SCREEN. Its spare height is
                  // shared evenly above the text, between text and buttons and
                  // below the buttons — the buttons stay low, near the thumb,
                  // without a hole in the middle — and the quick sections
                  // begin just below the fold.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      // Never negative, even in a tiny split-screen window.
                      minHeight: (box.maxHeight - 72).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // A new version waiting on Play is worth interrupting for —
                            // practising on an outdated question bank forever is worse.
                            const UpdateBanner(),
                            // Readiness, as on the website's home — signed-in
                            // users only; the same height in every state, so
                            // nothing below moves when the score arrives.
                            ReadinessStripSlot(
                              onOpen: () =>
                                  push(MyResultsScreen(onStartTest: startTest)),
                              onStart: startTest,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _Badge(text: s('home_badge')),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              s('home_title'),
                              style: TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.w800,
                                height: 1.22,
                                letterSpacing: -0.3,
                                color: AppTheme.textP(context),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              s('home_subtitle').replaceAll(
                                '{variants}',
                                AppStrings.variantsPhrase(
                                  QuestionService.variantCount,
                                  lang,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.55,
                                color: AppTheme.mutedText(context),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BrandButton(
                              label: s('home_btn_test'),
                              icon: const Icon(Icons.play_arrow_rounded),
                              minHeight: 60,
                              // The practice tab, not a second copy of it on top.
                              onPressed: () => context
                                  .findAncestorStateOfType<MainShellState>()
                                  ?.switchTab(MainShellState.practiceTab),
                            ),
                            const SizedBox(height: 12),
                            BrandButton(
                              label: s('home_btn_variants'),
                              icon: isPro
                                  ? crown
                                  : const Icon(Icons.grid_view_rounded),
                              kind: secondaryKind,
                              minHeight: 60,
                              onPressed: () => push(const VariantListScreen()),
                            ),
                            const SizedBox(height: 12),
                            BrandButton(
                              label: s('home_btn_topics'),
                              icon: isPro
                                  ? crown
                                  : const Icon(Icons.menu_book_rounded),
                              kind: secondaryKind,
                              minHeight: 60,
                              proTag: needsPro,
                              onPressed: () => push(const TopicListScreen()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionTile(
                    icon: Icons.timer_outlined,
                    color: AppTheme.error,
                    title: s('real_exam'),
                    onTap: () => push(const RealExamScreen(), fade: true),
                  ),
                  const SizedBox(height: 10),
                  SectionTile(
                    icon: Icons.psychology_outlined,
                    color: AppTheme.orange,
                    title: s('section_errors_drill'),
                    corner: needsPro ? const ProTag() : null,
                    onTap: () => push(const ErrorsScreen()),
                  ),
                  const SizedBox(height: 10),
                  SectionTile(
                    icon: Icons.warning_amber_rounded,
                    color: AppTheme.violet,
                    title: s('difficult_questions'),
                    corner: needsPro ? const ProTag() : null,
                    onTap: () => push(const DifficultQuestionsScreen()),
                  ),
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
                      onTap: () => push(const ProScreen()),
                    ),
                  ],
                ],
              ),
            ),
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
