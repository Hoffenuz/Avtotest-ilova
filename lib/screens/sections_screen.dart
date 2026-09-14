import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_access_gate.dart';
import 'avtodrom_screen.dart';
import 'difficult_questions_screen.dart';
import 'errors_screen.dart';
import 'memorize_screen.dart';
import 'question_search_screen.dart';
import 'real_exam_screen.dart';
import 'road_signs_screen.dart';
import 'saved_questions_screen.dart';

/// Hub screen behind the middle nav slot.
///
/// Grouped into two blocks because the list grew past the point where a flat
/// column reads: the things you *do* (an exam, a drill on your own mistakes)
/// come first, the things you *look up* (signs, numbers, penalties, search)
/// after. The section list itself mirrors the website's `siteSections.ts`.
class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    // A subscriber has already paid; reminding them on every row that these
    // sections cost money is noise at best and looks broken at worst.
    final hasPro = watchHasPro(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s('sections_title')),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _GroupLabel(text: s('section_practice')),
          // Open to everyone, like the website's /real-imtihon: the free tier
          // simply draws from the free question pool.
          _SectionCard(
            icon: Icons.assignment_turned_in_rounded,
            iconColor: AppTheme.error,
            title: s('real_exam'),
            subtitle: s('real_exam_sub'),
            onTap: () => Navigator.push(
              context,
              AppTheme.fadeRoute(const RealExamScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.bookmark_rounded,
            iconColor: AppTheme.orange,
            title: s('saved_tests'),
            subtitle: s('saved_tests_sub'),
            onTap: () => Navigator.push(
              context,
              AppTheme.slideRoute(const SavedQuestionsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.error_outline_rounded,
            iconColor: AppTheme.error,
            title: s('my_errors'),
            subtitle: s('my_errors_sub'),
            showProBadge: !hasPro,
            onTap: () => Navigator.push(
              context,
              AppTheme.slideRoute(const ErrorsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.psychology_alt_rounded,
            iconColor: AppTheme.blue,
            title: s('difficult_questions'),
            subtitle: s('difficult_questions_sub'),
            showProBadge: !hasPro,
            onTap: () => Navigator.push(
              context,
              AppTheme.slideRoute(const DifficultQuestionsScreen()),
            ),
          ),

          const SizedBox(height: 24),
          _GroupLabel(text: s('section_reference')),
          _SectionCard(
            icon: Icons.signpost_rounded,
            iconColor: AppTheme.success,
            title: s('road_signs'),
            subtitle: s('road_signs_sub'),
            onTap: () => Navigator.push(
              context,
              AppTheme.slideRoute(const RoadSignsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.speed_rounded,
            iconColor: AppTheme.blue,
            title: s('memorize'),
            subtitle: s('memorize_sub'),
            onTap: () => Navigator.push(
              context,
              AppTheme.slideRoute(const MemorizeScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.directions_car_filled_rounded,
            iconColor: AppTheme.orange,
            title: s('avtodrom'),
            subtitle: s('avtodrom_sub'),
            onTap: () => Navigator.push(
              context,
              AppTheme.slideRoute(const AvtodromScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.search_rounded,
            iconColor: AppTheme.blue,
            title: s('question_search'),
            subtitle: s('question_search_sub'),
            showProBadge: !hasPro,
            onTap: () => Navigator.push(
              context,
              AppTheme.slideRoute(const QuestionSearchScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.textM(context),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool showProBadge;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.showProBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                      height: 1.3,
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
            Icon(Icons.chevron_right_rounded, color: iconColor, size: 24),
          ],
        ),
      ),
    );
  }
}
