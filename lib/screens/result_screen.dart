import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/review_prompt_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/explanation_panel.dart';
import '../widgets/image_lightbox.dart';
import '../widgets/question_image.dart';
import 'test_screen.dart';

class ResultScreen extends StatefulWidget {
  final TestResult result;
  final List<Question> questions;
  final Map<String, int> selectedAnswers;
  final Set<String> incorrectIds;
  final String? testTitle;
  final Future<List<Question>> Function()? retakeLoadQuestions;
  final String? retakeTestType;
  final String? retakeTestLabel;
  final String? retakeTestKey;
  final int? retakeTimeLimitMinutes;
  final bool retakeCountUp;
  final String? retakeQuestionLang;

  /// Replaces the default "retake" behaviour of re-opening [TestScreen].
  /// The Real Exam passes this so a retry re-enters the exam interface with a
  /// fresh server session, instead of dropping the user into the ordinary
  /// test screen — which shows explanations and a language switch, neither of
  /// which an exam may have.
  final VoidCallback? onRetake;

  const ResultScreen({
    super.key,
    required this.result,
    required this.questions,
    required this.selectedAnswers,
    required this.incorrectIds,
    this.testTitle,
    this.retakeLoadQuestions,
    this.retakeTestType,
    this.retakeTestLabel,
    this.retakeTestKey,
    this.retakeTimeLimitMinutes,
    this.retakeCountUp = false,
    this.retakeQuestionLang,
    this.onRetake,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: widget.result.percentage)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
    _maybeAskForReview();
  }

  /// Asks Play for a rating once the score has finished counting up.
  ///
  /// The wait is not cosmetic: a system sheet that slides over a running
  /// animation reads as a glitch, and the user dismisses it before they have
  /// registered what it asked. [ReviewPromptService] decides whether anything
  /// is shown at all.
  Future<void> _maybeAskForReview() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    await ReviewPromptService.onTestFinished(
      percentage: widget.result.percentage,
      isPassed: widget.result.isPassed,
      isCompleted: widget.result.isCompleted,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Noto'g'ri javob berilgan savollar — test tartibida.
  List<Question> get _wrong => [
    for (final q in widget.questions)
      if (widget.incorrectIds.contains(q.globalId)) q,
  ];

  /// Faqat xato savollardan tuzilgan mashq (vaqt: savol boshiga 2 daqiqa,
  /// «Xatolar ustida ishlash» bo'limi bilan bir xil).
  void _startMistakesTest(List<Question> wrong, String lang, String qLang) {
    final title = AppStrings.get('mistakes_test', lang);
    Navigator.push(
      context,
      AppTheme.slideRoute(
        TestScreen(
          title: title,
          loadQuestions: () async => wrong,
          testType: 'practice',
          testLabel: title,
          timeLimitMinutes: wrong.length * 2,
          questionLang: qLang,
        ),
      ),
    );
  }

  /// Bitta xato savol: matn, rasm, javoblar (to'g'risi yashil, tanlangani
  /// qizil) va izoh. Izoh PRO'da ochiladi — qulf ExplanationPanel ichida.
  Future<void> _showMistake(Question q, String lang, String qLang) {
    final picked = widget.selectedAnswers[q.globalId];
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.border(ctx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  q.getText(qLang),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: AppTheme.textP(ctx),
                  ),
                ),
                if (q.mediaUrl != null && q.mediaUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  QuestionImage(
                    fileName: q.mediaUrl!,
                    maxHeight: 190,
                    zoomLabel: AppStrings.get('zoom_image', lang),
                    onTap: () => ImageLightbox.show(
                      ctx,
                      fileName: q.mediaUrl!,
                      uiLang: lang,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ...q.getOptions(qLang).indexed.map((e) {
                  final (i, o) = e;
                  final isPicked = o.id == picked;
                  final color = o.isCorrect
                      ? AppTheme.success
                      : isPicked
                      ? AppTheme.error
                      : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: color?.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: color?.withValues(alpha: 0.5) ??
                            AppTheme.border(ctx),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'F${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: color ?? AppTheme.textM(ctx),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            o.getText(qLang),
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.4,
                              color: AppTheme.textP(ctx),
                            ),
                          ),
                        ),
                        if (color != null)
                          Icon(
                            o.isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            size: 20,
                            color: color,
                          ),
                      ],
                    ),
                  );
                }),
                if (q.hasIzoh) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 20,
                        color: AppTheme.brandAccent(ctx),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.get('explanation_title', lang),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textP(ctx),
                        ),
                      ),
                    ],
                  ),
                  ExplanationPanel(question: q, lang: qLang, uiLang: lang),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final qLang = widget.retakeQuestionLang ?? lang;
    final wrong = _wrong;
    String s(String k) => AppStrings.get(k, lang);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Animated circle
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    final pct = (_scoreAnimation.value * 100).round();
                    return _ResultCircle(
                      percentage: pct,
                      progress: _scoreAnimation.value,
                      isPassed: widget.result.isPassed,
                      passedLabel: s('passed'),
                      failedLabel: s('not_passed'),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.result.isPassed
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: widget.result.isPassed
                          ? AppTheme.success.withValues(alpha: 0.3)
                          : AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    widget.result.isPassed ? s('congrats') : s('failed'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.result.isPassed
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.result.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textM(context),
                  ),
                ),
                const SizedBox(height: 24),

                // Stats row
                Row(
                  children: [
                    _StatCard(
                      label: s('correct'),
                      value: '${widget.result.correctAnswers}',
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      label: s('incorrect'),
                      value: '${widget.incorrectIds.length}',
                      icon: Icons.cancel_rounded,
                      color: AppTheme.error,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.cardDeco(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: AppTheme.brandAccent(context),
                      ),
                      const SizedBox(width: 8),
                      // Flexible: "Sarflangan vaqt: 17 daqiqa 12 soniya" is
                      // wider than a 320 dp phone and overflowed by 16 px.
                      Flexible(
                        child: Text(
                          '${s('time_spent')}: '
                          '${widget.result.timeSpentSeconds ~/ 60} '
                          '${s('minutes')} '
                          '${widget.result.timeSpentSeconds % 60} '
                          '${s('seconds')}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textS(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Xatolar: ro'yxatdan savolga o'tish va «Xatolar testi»
                if (wrong.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _MistakesCard(
                    title: s('result_mistakes'),
                    hint: s('result_mistakes_hint'),
                    questions: wrong,
                    questionLang: qLang,
                    onTap: (q) => _showMistake(q, lang, qLang),
                  ),
                  const SizedBox(height: 12),
                  BrandButton(
                    label: s('mistakes_test'),
                    icon: const Icon(Icons.rule_rounded),
                    kind: BrandButtonKind.success,
                    onPressed: () => _startMistakesTest(wrong, lang, qLang),
                  ),
                ],
                const SizedBox(height: 20),

                // Retake button
                if (widget.onRetake != null ||
                    widget.retakeLoadQuestions != null) ...[
                  BrandButton(
                    label: s('retake_test'),
                    icon: const Icon(Icons.replay_rounded),
                    // Starting a test is green everywhere in the app.
                    kind: BrandButtonKind.success,
                    onPressed:
                        widget.onRetake ??
                        () {
                          Navigator.pushReplacement(
                            context,
                            AppTheme.fadeRoute(
                              TestScreen(
                                title: widget.testTitle ?? widget.result.label,
                                loadQuestions: widget.retakeLoadQuestions!,
                                testType:
                                    widget.retakeTestType ?? widget.result.type,
                                testLabel:
                                    widget.retakeTestLabel ??
                                    widget.result.label,
                                testKey:
                                    widget.retakeTestKey ??
                                    widget.result.testKey,
                                timeLimitMinutes:
                                    widget.retakeTimeLimitMinutes ?? 60,
                                countUp: widget.retakeCountUp,
                                questionLang: widget.retakeQuestionLang,
                              ),
                            ),
                          );
                        },
                  ),
                  const SizedBox(height: 12),
                ],

                // Home button
                BrandButton(
                  label: s('go_home'),
                  icon: const Icon(Icons.home_rounded),
                  kind: BrandButtonKind.secondary,
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Noto'g'ri javob berilgan savollar ro'yxati. Ilgari natija ekranida faqat
/// «Xato: 4» raqami bor edi — QAYSI savollar ekanini ko'rib bo'lmasdi.
class _MistakesCard extends StatelessWidget {
  final String title;
  final String hint;
  final List<Question> questions;
  final String questionLang;
  final ValueChanged<Question> onTap;

  const _MistakesCard({
    required this.title,
    required this.hint,
    required this.questions,
    required this.questionLang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDeco(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$title · ${questions.length}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textP(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textM(context),
                  ),
                ),
              ],
            ),
          ),
          for (final (i, q) in questions.indexed)
            InkWell(
              onTap: () => onTap(q),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.getText(questionLang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: AppTheme.textP(context),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textM(context),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ResultCircle extends StatelessWidget {
  final int percentage;
  final double progress;
  final bool isPassed;
  final String passedLabel, failedLabel;

  const _ResultCircle({
    required this.percentage,
    required this.progress,
    required this.isPassed,
    required this.passedLabel,
    required this.failedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPassed ? AppTheme.success : AppTheme.error;
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
            backgroundColor: AppTheme.border(context),
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  isPassed ? passedLabel : failedLabel,
                  style: TextStyle(fontSize: 14, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: AppTheme.cardDeco(context),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.textM(context)),
            ),
          ],
        ),
      ),
    );
  }
}
