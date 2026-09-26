import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import 'test_screen.dart';

/// "Test ishlash": choose, check, start — in that order, top to bottom.
///
/// A count is only *selected*; its time and pass mark follow it, and the one
/// button that starts anything sits in the thumb's reach. 20 and 50 are what
/// people pick, so they are the two big cards; 75 and 100 are the occasional
/// marathon, a smaller pair underneath. Questions come in the app's own
/// language — a second language choice here was one step too many.
class PracticeSetupScreen extends StatefulWidget {
  final bool embedded;
  const PracticeSetupScreen({super.key, this.embedded = false});

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  /// Minutes track the real exam pace — 20 questions in 25 minutes — so a
  /// longer set feels the same, not more rushed.
  static const Map<int, int> _minutesFor = {20: 25, 50: 60, 75: 90, 100: 120};

  static const List<int> _mainCounts = [20, 50];
  static const List<int> _extraCounts = [75, 100];

  int _count = 20;

  void _startPractice(int count, int timeMinutes) {
    final uiLang = context.read<LanguageProvider>().lang;
    final route = AppTheme.slideRoute(
      TestScreen(
        title: '$count ${AppStrings.get('n_questions', uiLang)}',
        loadQuestions: () =>
            QuestionService.loadPracticeQuestions(count: count),
        testType: 'practice',
        testLabel: '$count ${AppStrings.get('n_question_test', uiLang)}',
        timeLimitMinutes: timeMinutes,
        questionLang: uiLang,
      ),
    );

    // Embedded, this screen IS a bottom-nav tab and has no route of its own —
    // replacing would tear down the whole shell and leave the user with no
    // navigation bar to come back to.
    if (widget.embedded) {
      Navigator.push(context, route);
    } else {
      Navigator.pushReplacement(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);
    final minutes = _minutesFor[_count]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(s('menu_test')),
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Column(
        children: [
          Expanded(
            // The choice sits in the middle of the free space, not pinned to
            // the top with an empty half-screen under it.
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight - 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(
                        title: s('choose_count'),
                        hint: s('random_questions'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          for (final c in _mainCounts) ...[
                            if (c != _mainCounts.first)
                              const SizedBox(width: 10),
                            Expanded(
                              child: _CountCard(
                                count: c,
                                unit: s('n_questions'),
                                selected: c == _count,
                                onTap: () => setState(() => _count = c),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (final c in _extraCounts) ...[
                            if (c != _extraCounts.first)
                              const SizedBox(width: 10),
                            Expanded(
                              child: _ExtraCount(
                                label: '$c ${s('n_questions')}',
                                selected: c == _count,
                                onTap: () => setState(() => _count = c),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      // The count is already on the selected card; only what follows
                      // from it is repeated here.
                      StatCells(
                        cells: [
                          ('$minutes', s('stat_minutes')),
                          ('90%', s('stat_pass')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.isDark(context)
                  ? AppTheme.scaffoldBg
                  : AppTheme.lightScaffoldBg,
              border: Border(
                top: BorderSide(color: AppTheme.hairline(context)),
              ),
            ),
            child: SafeArea(
              top: false,
              // In the shell the tab bar already clears the system inset.
              bottom: !widget.embedded,
              child: BrandButton(
                label: s('start_test'),
                icon: const Icon(Icons.play_arrow_rounded),
                minHeight: 56,
                onPressed: () => _startPractice(_count, minutes),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String hint;
  const _SectionLabel({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textP(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppTheme.mutedText(context)),
        ),
      ],
    );
  }
}

/// 20 / 50 — the big pair. The chosen one is filled with the brand gradient,
/// so the choice reads at a glance without a tick in the corner.
class _CountCard extends StatelessWidget {
  final int count;
  final String unit;
  final bool selected;
  final VoidCallback onTap;

  const _CountCard({
    required this.count,
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLg);
    final fg = selected ? Colors.white : AppTheme.textP(context);
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          color: selected ? null : AppTheme.card(context),
          borderRadius: radius,
          border: selected
              ? null
              : Border.all(color: AppTheme.hairline(context)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.blueDark.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppTheme.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 75 / 100 — the same choice as the big cards, one size down.
class _ExtraCount extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ExtraCount({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.brandAccent(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? accent.withValues(alpha: AppTheme.isDark(context) ? 0.16 : 0.06)
            : AppTheme.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          side: BorderSide(
            color: selected ? accent : AppTheme.hairline(context),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? accent : AppTheme.textS(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
