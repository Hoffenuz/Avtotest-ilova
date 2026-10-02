import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/readiness_widgets.dart';
import '../widgets/update_banner.dart';
import 'difficult_questions_screen.dart';
import 'errors_screen.dart';
import 'main_shell.dart';
import 'profile_screen.dart';
import 'pro_screen.dart';
import 'real_exam_screen.dart';
import 'topic_list_screen.dart';
import 'variant_list_screen.dart';

/// Bosh ekran — mobil ilova uchun: tepada tayyorgarlik, keyin asosiy harakat
/// ko'k kartada ("Test ishlash"), ostida ikki yonma-yon karta (Variantlar,
/// Mavzular) va tezkor bo'limlar ro'yxati. Bo'sh joy yo'q, hamma narsa bir
/// qarashda; qorong'i rejimda ham kartalar fondan yumshoq ajralib turadi.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String key) => AppStrings.get(key, lang);

    final isLoggedIn = context.select<AuthProvider, bool>((a) => a.isLoggedIn);
    // `isDeniedForSure`, not `!isPro`: before the access RPC answers, `isPro`
    // is false for everyone, and a subscriber would watch PRO badges appear
    // on their own content for a frame and then vanish.
    final isDeniedForSure = context.select<SubscriptionProvider, bool>(
      (sub) => sub.isDeniedForSure,
    );
    final needsPro = !isLoggedIn || isDeniedForSure;
    final variants = AppStrings.variantsPhrase(
      QuestionService.variantCount,
      lang,
    );

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

    return Scaffold(
      body: Column(
        children: [
          BrandHeader(
            onPro: () => push(const ProScreen()),
            actions: const [LanguageMenu()],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                // A new version waiting on Play is worth interrupting for —
                // practising on an outdated question bank forever is worse.
                const UpdateBanner(),
                // Readiness, as on the website — signed-in users only; the
                // same height in every state, so nothing below moves.
                ReadinessStripSlot(
                  onOpen: () => push(MyResultsScreen(onStartTest: startTest)),
                  onStart: startTest,
                  gap: 14,
                ),
                _HeroCard(
                  badge: s('home_badge'),
                  title: s('home_hero_title'),
                  subtitle: s(
                    'home_hero_sub',
                  ).replaceAll('{variants}', variants),
                  action: s('home_btn_test'),
                  onTap: startTest,
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.grid_view_rounded,
                          color: AppTheme.blueDark,
                          title: s('home_btn_variants'),
                          subtitle: variants,
                          onTap: () => push(const VariantListScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.menu_book_rounded,
                          color: AppTheme.orange,
                          title: s('home_btn_topics'),
                          subtitle: s('home_topics_sub'),
                          pro: needsPro,
                          onTap: () => push(const TopicListScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 10),
                  child: Text(
                    s('quick_actions'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textP(context),
                    ),
                  ),
                ),
                SectionTile(
                  icon: Icons.timer_outlined,
                  color: AppTheme.error,
                  title: s('real_exam'),
                  subtitle: s('real_exam_sub'),
                  onTap: () => push(const RealExamScreen(), fade: true),
                ),
                const SizedBox(height: 10),
                SectionTile(
                  icon: Icons.psychology_outlined,
                  color: AppTheme.orange,
                  title: s('section_errors_drill'),
                  subtitle: s('my_errors_sub'),
                  corner: needsPro ? const ProTag() : null,
                  onTap: () => push(const ErrorsScreen()),
                ),
                const SizedBox(height: 10),
                SectionTile(
                  icon: Icons.warning_amber_rounded,
                  color: AppTheme.violet,
                  title: s('difficult_questions'),
                  subtitle: s('difficult_questions_sub'),
                  corner: needsPro ? const ProTag() : null,
                  onTap: () => push(const DifficultQuestionsScreen()),
                ),
                if (needsPro) ...[
                  const SizedBox(height: 20),
                  ProUpsellCard(
                    title: s('pro_card_title'),
                    description: s(
                      'pro_card_desc',
                    ).replaceAll('{variants}', variants),
                    action: s('get_pro'),
                    onTap: () => push(const ProScreen()),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The main action on a blue card: what the app is for, and the one button
/// that starts it. A faint car in the corner — the only ornament.
class _HeroCard extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  const _HeroCard({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final radius = BorderRadius.circular(AppTheme.radiusXl);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.blue, Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.blueDark.withValues(alpha: dark ? 0.25 : 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(
                Icons.directions_car_filled_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onTap,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 52),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: AppTheme.blueDark,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  action,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppTheme.blueDark,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A half-width card: coloured icon, name, one line about it.
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool pro;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.pro = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final card = Material(
      color: AppTheme.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.hairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: dark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textP(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: AppTheme.mutedText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!pro) return card;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        card,
        const Positioned(right: -4, top: -8, child: ProTag()),
      ],
    );
  }
}
