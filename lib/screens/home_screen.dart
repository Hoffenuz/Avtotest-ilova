import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avtodrom_card.dart';
import '../widgets/brand.dart';
import '../widgets/home_hero.dart';
import '../widgets/update_banner.dart';
import '../widgets/readiness_widgets.dart';
import 'difficult_questions_screen.dart';
import 'errors_screen.dart';
import 'main_shell.dart';
import 'pro_screen.dart';
import '../widgets/sources_note.dart';
import 'real_exam_screen.dart';
import 'my_results_screen.dart';
import 'road_signs_screen.dart';
import 'topic_list_screen.dart';
import 'variant_list_screen.dart';

/// Bosh ekran — saytning bosh sahifasi (src/pages/Home.tsx) bilan bir xil
/// tartibda: nishon, sarlavha, qisqa izoh, uchta katta tugma
/// (MainTestButtons), keyin tezkor bo'limlar (QUICK_ITEMS). Natijalar
/// Sozlamalar → Natijalarim da.
///
/// Hero bo'sh matn varag'i bo'lib qolmasligi uchun (widgets/home_hero.dart):
/// saytdagi katak fon va yorug'lik, nishon yonida uchta haqiqiy yo'l belgisi,
/// izoh ostida bazadan o'qiladigan ko'rsatkichlar (savollar, variantlar,
/// belgilar) — har biri o'z bo'limini ochadi.
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
          // Readiness sits right under the header and stays there while the
          // page scrolls — signed-in users only; the same height in every
          // state, so nothing below moves when the score arrives.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: ReadinessStripSlot(
              gap: 0,
              onOpen: () => push(MyResultsScreen(onStartTest: startTest)),
              onStart: startTest,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                children: [
                  // Hero ixcham: qisqa sarlavha, bir jumla izoh, uchta
                  // ko'rsatkich va tugmalar — hammasi birinchi ekranda,
                  // tugmalar pastga «itarilmaydi».
                  // Behind the hero: the website's faint grid and blue glow
                  // (src/pages/Home.tsx), so the first screen is not a flat
                  // sheet of text. Bleeds 16px past the list padding on each
                  // side and fades out before the quick sections.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned(
                        left: -16,
                        right: -16,
                        top: -20,
                        bottom: 0,
                        child: HeroBackdrop(),
                      ),
                      // Tabiiy oqim: tugmalar statistikadan keyin darhol,
                      // ekran pastiga «itarilmaydi» — barmoqqa yaqinroq va
                      // bosh ekranda ko'proq narsa ko'rinadi.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // A new version waiting on Play is worth interrupting for —
                              // practising on an outdated question bank forever is worse.
                              const UpdateBanner(),
                              // Sarlavha chapda, uchta yo'l belgisi o'ngda — ilova
                              // mavzusi bir qarashda. Yorliq va izoh olib tashlandi
                              // (2026-11-05, egasi: hero'da yozuv ko'payib ketgan).
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      s('home_title'),
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                        letterSpacing: -0.3,
                                        color: AppTheme.textP(context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const HeroSignCluster(),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // What is inside, in numbers read from the bank
                              // itself — each one opens its section.
                              HeroStatsRow(
                                lang: lang,
                                onQuestions: startTest,
                                onVariants: () =>
                                    push(const VariantListScreen()),
                                onSigns: () => push(const RoadSignsScreen()),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BrandButton(
                                kind: BrandButtonKind.success,
                                label: s('home_btn_test'),
                                icon: const Icon(Icons.play_arrow_rounded),
                                minHeight: 56,
                                // The practice tab, not a second copy of it on top.
                                onPressed: () => context
                                    .findAncestorStateOfType<MainShellState>()
                                    ?.switchTab(MainShellState.practiceTab),
                              ),
                              const SizedBox(height: 10),
                              // Ikkita ikkilamchi tugma yonma-yon: bitta
                              // qator kam joy oladi, ikkalasi ham ko'rinadi.
                              Row(
                                children: [
                                  Expanded(
                                    child: BrandButton(
                                      label: s('home_btn_variants'),
                                      icon: isPro
                                          ? crown
                                          : const Icon(Icons.grid_view_rounded),
                                      kind: secondaryKind,
                                      dense: true,
                                      minHeight: 54,
                                      onPressed: () =>
                                          push(const VariantListScreen()),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: BrandButton(
                                      label: s('home_btn_topics'),
                                      icon: isPro
                                          ? crown
                                          : const Icon(Icons.menu_book_rounded),
                                      kind: secondaryKind,
                                      dense: true,
                                      minHeight: 54,
                                      proTag: needsPro,
                                      onPressed: () =>
                                          push(const TopicListScreen()),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Avtodrom simulyatori — hero'dan keyin, doimiy joyda.
                  AvtodromCard(lang: lang),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  const SourcesNote(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
