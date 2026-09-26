import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/review_prompt_service.dart';
import '../theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
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
                      const Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: AppTheme.blue,
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
                const SizedBox(height: 32),

                // Retake button
                if (widget.onRetake != null ||
                    widget.retakeLoadQuestions != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                      onPressed:
                          widget.onRetake ??
                          () {
                            Navigator.pushReplacement(
                              context,
                              AppTheme.fadeRoute(
                                TestScreen(
                                  title:
                                      widget.testTitle ?? widget.result.label,
                                  loadQuestions: widget.retakeLoadQuestions!,
                                  testType:
                                      widget.retakeTestType ??
                                      widget.result.type,
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
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(
                        s('retake_test'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Home button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.blue),
                      foregroundColor: AppTheme.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home_rounded),
                    label: Text(
                      s('go_home'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
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
