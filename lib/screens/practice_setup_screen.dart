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
/// Tapping a count used to start the test at once, so there was no moment to
/// see what was about to happen or to change the language first; the language
/// card sat above the counts and was easy to miss. Now a count is only
/// *selected*, its time and pass mark follow it, and the one button
/// that starts anything sits in the thumb's reach.
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

  late String _sessionLang;
  int _count = 20;

  @override
  void initState() {
    super.initState();
    _sessionLang = context.read<LanguageProvider>().lang;
  }

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
        questionLang: _sessionLang,
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _SectionLabel(
                  title: s('choose_count'),
                  hint: s('random_questions'),
                ),
                const SizedBox(height: 12),
                _CountGrid(
                  counts: _minutesFor.keys.toList(),
                  selected: _count,
                  unit: s('n_questions'),
                  onSelect: (c) => setState(() => _count = c),
                ),
                const SizedBox(height: 12),
                // The count is already on the selected card; only what follows
                // from it is repeated here.
                StatCells(
                  cells: [
                    ('$minutes', s('stat_minutes')),
                    ('90%', s('stat_pass')),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionLabel(
                  title: s('test_session_language'),
                  hint: s('test_session_language_hint'),
                ),
                const SizedBox(height: 12),
                _LanguageSegments(
                  selected: _sessionLang,
                  onChanged: (code) => setState(() => _sessionLang = code),
                ),
              ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          hint,
          style: TextStyle(fontSize: 13, color: AppTheme.mutedText(context)),
        ),
      ],
    );
  }
}

/// Four equal choices, two by two. Picking one only selects it; the number is
/// the big thing on the card because it is the thing being chosen.
class _CountGrid extends StatelessWidget {
  final List<int> counts;
  final int selected;
  final String unit;
  final ValueChanged<int> onSelect;

  const _CountGrid({
    required this.counts,
    required this.selected,
    required this.unit,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < counts.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + 2 && j < counts.length; j++) ...[
                if (j > i) const SizedBox(width: 10),
                Expanded(
                  child: _CountCard(
                    count: counts[j],
                    unit: unit,
                    selected: counts[j] == selected,
                    onTap: () => onSelect(counts[j]),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

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
    final accent = AppTheme.brandAccent(context);
    final radius = BorderRadius.circular(AppTheme.radiusMd);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? accent.withValues(alpha: AppTheme.isDark(context) ? 0.16 : 0.06)
            : AppTheme.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? accent : AppTheme.hairline(context),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: selected ? accent : AppTheme.textP(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                    color: accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three question languages side by side; the chosen one is filled.
class _LanguageSegments extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _LanguageSegments({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final fill = AppTheme.brandFill(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.hairline(context)),
      ),
      child: Row(
        children: [
          for (final l in LanguageProvider.languages)
            Expanded(
              child: Semantics(
                button: true,
                selected: l['code'] == selected,
                child: Material(
                  color: l['code'] == selected ? fill : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onChanged(l['code']!),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l['label']!,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: l['code'] == selected
                                    ? Colors.white
                                    : AppTheme.textS(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
