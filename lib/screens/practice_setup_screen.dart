import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import 'test_screen.dart';

class PracticeSetupScreen extends StatefulWidget {
  final bool embedded;
  const PracticeSetupScreen({super.key, this.embedded = false});

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  late String _sessionLang;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(s('menu_test')),
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: AppTheme.glassDeco(context),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16),
                ),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.blueGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blue.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.play_circle_filled_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s('choose_count'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s('random_questions'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SessionLanguagePicker(
              selectedLang: _sessionLang,
              uiLang: lang,
              onChanged: (code) => setState(() => _sessionLang = code),
            ),
            const SizedBox(height: 28),
            // Minutes track the real exam pace — 20 questions in 25 minutes
            // — so a longer set feels the same, not more rushed.
            //
            // 20 and 50 are what people actually pick, so they get full-width
            // cards. 75 and 100 are the occasional marathon: a pair of small
            // buttons on one row, present without competing for attention.
            _PracticeOption(
              count: 20,
              timeMinutes: 25,
              lang: lang,
              gradient: AppTheme.blueGradient,
              onTap: () => _startPractice(20, 25),
            ),
            const SizedBox(height: 12),
            _PracticeOption(
              count: 50,
              timeMinutes: 60,
              lang: lang,
              gradient: AppTheme.orangeGradient,
              onTap: () => _startPractice(50, 60),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SmallPracticeOption(
                  count: 75,
                  timeMinutes: 90,
                  lang: lang,
                  onTap: () => _startPractice(75, 90),
                ),
                const SizedBox(width: 12),
                _SmallPracticeOption(
                  count: 100,
                  timeMinutes: 120,
                  lang: lang,
                  onTap: () => _startPractice(100, 120),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The longer sets, at half width.
///
/// Same wording and the same shape as the full-size cards, just smaller: a
/// marathon is the same action as a short drill, only rarer, so it belongs in
/// the same list without competing with the two people actually pick.
class _SmallPracticeOption extends StatelessWidget {
  final int count;
  final int timeMinutes;
  final String lang;
  final VoidCallback onTap;

  const _SmallPracticeOption({
    required this.count,
    required this.timeMinutes,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count ${AppStrings.get('n_questions', lang)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textP(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$timeMinutes ${AppStrings.get('n_minutes', lang)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textM(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.play_arrow_rounded,
                  color: AppTheme.blue,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionLanguagePicker extends StatelessWidget {
  final String selectedLang;
  final String uiLang;
  final ValueChanged<String> onChanged;

  const _SessionLanguagePicker({
    required this.selectedLang,
    required this.uiLang,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, uiLang);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.translate_rounded,
                size: 20,
                color: AppTheme.blue,
              ),
              const SizedBox(width: 8),
              Text(
                s('test_session_language'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textP(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s('test_session_language_hint'),
            style: TextStyle(fontSize: 12.5, color: AppTheme.textM(context)),
          ),
          const SizedBox(height: 12),
          ...LanguageProvider.languages.map((l) {
            final code = l['code']!;
            final selected = code == selectedLang;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  onTap: () => onChanged(code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.blue.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: selected
                            ? AppTheme.blue.withValues(alpha: 0.35)
                            : AppTheme.border(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selected
                              ? AppTheme.blue
                              : AppTheme.textM(context),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l['label']!,
                          style: TextStyle(
                            color: selected
                                ? AppTheme.blue
                                : AppTheme.textS(context),
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PracticeOption extends StatelessWidget {
  final int count;
  final int timeMinutes;
  final String lang;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PracticeOption({
    required this.count,
    required this.timeMinutes,
    required this.lang,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count ${AppStrings.get('n_questions', lang)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textP(context),
                    ),
                  ),
                  Text(
                    '$timeMinutes ${AppStrings.get('n_minutes', lang)}',
                    style: TextStyle(color: AppTheme.textM(context)),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppTheme.blue,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
