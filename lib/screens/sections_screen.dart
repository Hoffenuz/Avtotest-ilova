import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/premium_access_gate.dart';
import 'avtodrom_screen.dart';
import 'difficult_questions_screen.dart';
import 'errors_screen.dart';
import 'memorize_screen.dart';
import 'question_search_screen.dart';
import 'real_exam_screen.dart';
import 'road_signs_screen.dart';
import 'saved_questions_screen.dart';

/// Hub screen behind the second nav slot.
///
/// The same two groups as the website's `SECTION_GROUPS`
/// (src/lib/siteSections.ts): what you *do* to get ready — an exam, your own
/// mistakes, saved and hard questions — then what you *learn* from. One tile
/// style for every row, ink icons, and the PRO mark in the corner so it never
/// takes room from the name.
class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    // A subscriber has already paid; reminding them on every row that these
    // sections cost money is noise at best and looks broken at worst.
    final hasPro = watchHasPro(context);

    void open(Widget screen, {bool fade = false}) => Navigator.push(
      context,
      fade ? AppTheme.fadeRoute(screen) : AppTheme.slideRoute(screen),
    );

    Widget tile(
      IconData icon,
      String key,
      Widget screen, {
      bool pro = false,
      bool fade = false,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SectionTile(
          icon: icon,
          title: s(key),
          subtitle: s('${key}_sub'),
          corner: pro && !hasPro ? const ProTag() : null,
          onTap: () => open(screen, fade: fade),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s('sections_title')),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _GroupLabel(text: s('section_practice')),
          // Open to everyone: the free tier simply draws from the free pool.
          tile(
            Icons.timer_outlined,
            'real_exam',
            const RealExamScreen(),
            fade: true,
          ),
          tile(
            Icons.cancel_outlined,
            'my_errors',
            const ErrorsScreen(),
            pro: true,
          ),
          tile(
            Icons.bookmark_border_rounded,
            'saved_tests',
            const SavedQuestionsScreen(),
          ),
          tile(
            Icons.warning_amber_rounded,
            'difficult_questions',
            const DifficultQuestionsScreen(),
            pro: true,
          ),
          const SizedBox(height: 14),
          _GroupLabel(text: s('section_reference')),
          tile(Icons.signpost_outlined, 'road_signs', const RoadSignsScreen()),
          tile(Icons.traffic_outlined, 'avtodrom', const AvtodromScreen()),
          tile(Icons.tag_rounded, 'memorize', const MemorizeScreen()),
          tile(
            Icons.search_rounded,
            'question_search',
            const QuestionSearchScreen(),
            pro: true,
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
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textP(context),
        ),
      ),
    );
  }
}
