import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/settings_provider.dart';
import '../services/app_strings.dart';
import '../services/storage_service.dart';
import '../services/test_results_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/explanation_panel.dart';
import '../widgets/ha_yo_dialog.dart';
import '../widgets/image_lightbox.dart';
import '../widgets/question_image.dart';
import 'result_screen.dart';

class TestScreen extends StatefulWidget {
  final String title;
  final Future<List<Question>> Function() loadQuestions;
  final String testType;
  final String testLabel;
  final String? testKey;
  final int timeLimitMinutes;

  /// When true, the timer counts up from 0 with no auto-submit — used by
  /// topic tests, which are untimed (matches the website: topic tests are a
  /// stopwatch, only exam variants have a real countdown).
  final bool countUp;

  /// Language for question/answer text. Defaults to the app UI language.
  final String? questionLang;

  /// Server-tracked session id from [TestSessionService.startSession],
  /// required to persist topic/variant results via
  /// `verify_and_save_test_result`. Null for practice tests.
  final String? sessionId;

  const TestScreen({
    super.key,
    required this.title,
    required this.loadQuestions,
    required this.testType,
    required this.testLabel,
    this.testKey,
    this.timeLimitMinutes = 60,
    this.countUp = false,
    this.questionLang,
    this.sessionId,
  });

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with TickerProviderStateMixin {
  List<Question> _questions = [];
  int _currentIndex = 0;
  final Map<String, int> _selectedAnswers = {};
  final Set<String> _incorrectIds = {};

  /// Ticks once a second. Kept out of [State] fields on purpose: rebuilding
  /// the whole screen (PageView + number strip + every answer tile) every
  /// second was the main source of jank during a test. Only the timer chip
  /// listens to it now.
  late final ValueNotifier<int> _timeLeft;
  Timer? _timer;
  bool _loading = true;
  String? _error;
  bool _finished = false;
  late DateTime _startTime;
  late PageController _pageController;
  final Set<String> _savedIds = {};

  /// The pending move to the next question. Kept so it can be cancelled: the
  /// user may move on by hand, or switch the feature off, inside the delay —
  /// and a jump that fires anyway lands them somewhere they did not choose.
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _timeLeft = ValueNotifier<int>(
      widget.countUp ? 0 : widget.timeLimitMinutes * 60,
    );
    _startTime = DateTime.now();
    _pageController = PageController();
    _loadSavedIds();
    _loadData();
  }

  Future<void> _loadSavedIds() async {
    final ids = await StorageService.getSavedQuestions();
    if (!mounted) return;
    setState(
      () => _savedIds
        ..clear()
        ..addAll(ids),
    );
  }

  Future<void> _toggleSaveCurrent(String lang) async {
    if (_questions.isEmpty) return;
    final q = _questions[_currentIndex];
    final saved = _savedIds.contains(q.globalId);

    if (saved) {
      await StorageService.removeSavedQuestion(q.globalId);
      setState(() => _savedIds.remove(q.globalId));
    } else {
      await StorageService.addSavedQuestion(q.globalId);
      setState(() => _savedIds.add(q.globalId));
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.get(saved ? 'question_unsaved' : 'question_saved', lang),
          style: const TextStyle(fontSize: 13),
        ),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 72),
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final questions = await widget.loadQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
      _startTimer();
      _precacheAround(0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Decodes the images of the neighbouring questions ahead of time. Without
  /// this, swiping to a question that has a picture decodes it mid-gesture and
  /// drops frames right when the page is animating.
  void _precacheAround(int index) {
    if (!mounted || _questions.isEmpty) return;

    for (var i = index - 1; i <= index + 2; i++) {
      if (i < 0 || i >= _questions.length) continue;
      final media = _questions[i].mediaUrl;
      if (media == null || media.isEmpty) continue;
      precacheImage(
        // The width MUST match what QuestionImage asks for, or this warms a
        // different cache entry and the decode is done twice — once here and
        // thrown away, once again when the card is built.
        ResizeImage.resizeIfNeeded(
          QuestionImage.decodeWidthFor(context, media),
          null,
          AssetImage('assets/tests-json/images/$media'),
        ),
        context,
        onError: (_, _) {},
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (widget.countUp) {
        _timeLeft.value++;
      } else {
        _timeLeft.value--;
        if (_timeLeft.value <= 0) {
          timer.cancel();
          _finishTest();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _advanceTimer?.cancel();
    _timeLeft.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _selectAnswer(Question question, int optionId, String lang) {
    if (_selectedAnswers.containsKey(question.globalId)) return;

    final options = question.getOptions(lang);
    final selected = options.firstWhere((o) => o.id == optionId);

    setState(() {
      _selectedAnswers[question.globalId] = optionId;
      // Feeds the per-topic breakdown; see TopicStatsService.
      StorageService.recordAnswer(question.globalId, selected.isCorrect);
      if (!selected.isCorrect) {
        _incorrectIds.add(question.globalId);
        StorageService.addErrorQuestion(question.globalId);
      } else {
        // Answering correctly clears the question from "my mistakes" —
        // previously nothing ever called removeErrorQuestion, so a question
        // missed once stayed on that list forever.
        StorageService.removeErrorQuestion(question.globalId);
      }
    });

    // OPENING THE EXPLANATION ON A WRONG ANSWER IS OPT-IN.
    //
    // A wrong answer is the best moment to read why — but a sheet that opens
    // by itself is also an interruption, and during a 100-question drill it is
    // a hundred of them. So it is off unless the user has asked for it in
    // Settings. Still PRO-only when on: for anyone else it would be an upsell
    // popping up on every mistake.
    final showExplanation =
        !selected.isCorrect &&
        question.hasIzoh &&
        context.read<SettingsProvider>().autoExplanation &&
        context.read<SubscriptionProvider>().isPro;

    if (showExplanation) {
      final uiLang = context.read<LanguageProvider>().lang;
      // Let the red register before the sheet slides over it.
      Future.delayed(const Duration(milliseconds: 450), () async {
        if (!mounted) return;
        await _showExplanationSheet(
          context,
          question: question,
          lang: lang,
          uiLang: uiLang,
        );
        // Auto-advance waits for the sheet: moving on underneath it would
        // leave the explanation describing a question no longer on screen.
        if (mounted) _scheduleAutoAdvance(delay: Duration.zero);
      });
      return;
    }

    _scheduleAutoAdvance();
  }

  /// Moves to the next unanswered question, or finishes when there is none.
  void _scheduleAutoAdvance({
    Duration delay = const Duration(milliseconds: 1200),
  }) {
    _advanceTimer?.cancel();
    if (!context.read<SettingsProvider>().autoAdvance) return;
    final answeredIndex = _currentIndex;
    _advanceTimer = Timer(delay, () {
      if (!mounted || _finished) return;
      // Re-checked on firing: the user may have moved on by hand or switched
      // the feature off while the delay ran.
      if (_currentIndex != answeredIndex ||
          !context.read<SettingsProvider>().autoAdvance) {
        return;
      }
      final nextIndex = _findNextUnanswered(_currentIndex);
      if (nextIndex == -1) {
        _finishTest();
      } else {
        _goToQuestion(nextIndex);
      }
    });
  }

  int _findNextUnanswered(int from) {
    for (int i = from + 1; i < _questions.length; i++) {
      if (!_selectedAnswers.containsKey(_questions[i].globalId)) return i;
    }
    for (int i = 0; i < from; i++) {
      if (!_selectedAnswers.containsKey(_questions[i].globalId)) return i;
    }
    return -1;
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    _advanceTimer?.cancel();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  String get _questionLang =>
      widget.questionLang ?? context.read<LanguageProvider>().lang;

  void _finishTest() {
    // The timer expiring, auto-advance reaching the end and the finish dialog
    // can all fire within the same frame — without this guard the result
    // screen gets pushed more than once.
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    final timeSpent = DateTime.now().difference(_startTime).inSeconds;
    final lang = _questionLang;
    final correctCount = _questions.where((q) {
      final selected = _selectedAnswers[q.globalId];
      if (selected == null) return false;
      final options = q.getOptions(lang);
      final correct = options.where((o) => o.isCorrect).firstOrNull;
      return correct != null && correct.id == selected;
    }).length;

    final answeredAll = _selectedAnswers.length >= _questions.length;
    final result = TestResult(
      type: widget.testType,
      testKey: widget.testKey,
      label: widget.testLabel,
      totalQuestions: _questions.length,
      correctAnswers: correctCount,
      timeSpentSeconds: timeSpent,
      date: DateTime.now(),
      isCompleted: answeredAll,
    );

    TestResultsService.save(result, sessionId: widget.sessionId);
    // The per-question tally is written on a timer; a finished test is the
    // natural point to make sure none of it is still only in memory.
    StorageService.flushQuestionStats();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      AppTheme.fadeRoute(
        ResultScreen(
          result: result,
          questions: _questions,
          selectedAnswers: _selectedAnswers,
          incorrectIds: _incorrectIds,
          testTitle: widget.title,
          retakeLoadQuestions: widget.loadQuestions,
          retakeTestType: widget.testType,
          retakeTestLabel: widget.testLabel,
          retakeTestKey: widget.testKey,
          retakeTimeLimitMinutes: widget.timeLimitMinutes,
          retakeCountUp: widget.countUp,
          retakeQuestionLang: widget.questionLang,
        ),
      ),
    );
  }

  Future<void> _showExplanationSheet(
    BuildContext context, {
    required Question question,
    required String lang,
    required String uiLang,
  }) {
    String s(String k) => AppStrings.get(k, uiLang);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppTheme.blue),
                      const SizedBox(width: 8),
                      Text(
                        s('explanation_title'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textP(ctx),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  ExplanationPanel(
                    question: question,
                    lang: lang,
                    uiLang: uiLang,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExitDialog() async {
    final lang = context.read<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);
    final ok = await showHaYoDialog(
      context,
      title: s('exit_test'),
      message: s('exit_test_msg'),
      lang: lang,
      yesLabel: s('yes'),
      noLabel: s('no'),
      destructive: true,
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  Future<void> _showFinishDialog() async {
    final lang = context.read<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);
    final unanswered = _questions
        .where((q) => !_selectedAnswers.containsKey(q.globalId))
        .length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_rounded, size: 44, color: AppTheme.blue),
              const SizedBox(height: 14),
              Text(
                s('finish_test'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textP(ctx),
                ),
              ),
              const SizedBox(height: 16),
              _DialogStatRow(
                label: s('answered'),
                value: '${_questions.length - unanswered}',
                color: AppTheme.success,
              ),
              _DialogStatRow(
                label: s('unanswered'),
                value: '$unanswered',
                color: AppTheme.orange,
              ),
              _DialogStatRow(
                label: s('total'),
                value: '${_questions.length}',
                color: AppTheme.blue,
              ),
              if (unanswered > 0) ...[
                const SizedBox(height: 10),
                Text(
                  '$unanswered ${s('unanswered_warning')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.orange, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        side: BorderSide(color: AppTheme.border(ctx)),
                      ),
                      child: Text(
                        s('no'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textP(ctx),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: AppTheme.blue,
                      ),
                      child: Text(
                        s('yes'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) _finishTest();
  }

  @override
  Widget build(BuildContext context) {
    final uiLang = context.watch<LanguageProvider>().lang;
    final qLang = _questionLang;
    String s(String k) => AppStrings.get(k, uiLang);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: AppTheme.blue,
                  strokeWidth: 3,
                  backgroundColor: AppTheme.card(context),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s('loading'),
                style: TextStyle(color: AppTheme.textS(context)),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '${s('error_prefix')}: $_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textS(context)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s('back')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Text(
            s('no_questions'),
            style: TextStyle(color: AppTheme.textS(context)),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: AppTheme.isDark(context)
            ? AppTheme.scaffoldBg
            : AppTheme.lightScaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              _TestToolbar(
                timeLeft: _timeLeft,
                countUp: widget.countUp,
                autoAdvance: context.watch<SettingsProvider>().autoAdvance,
                isCurrentSaved:
                    _questions.isNotEmpty &&
                    _savedIds.contains(_questions[_currentIndex].globalId),
                autoAdvanceTooltip: s('auto_advance'),
                finishTooltip: s('finish'),
                exitTooltip: s('exit_test'),
                saveTooltip:
                    _questions.isNotEmpty &&
                        _savedIds.contains(_questions[_currentIndex].globalId)
                    ? s('unsave_question')
                    : s('save_question'),
                onToggleSave: () => _toggleSaveCurrent(uiLang),
                onToggleAutoAdvance: () {
                  final settings = context.read<SettingsProvider>();
                  final enable = !settings.autoAdvance;
                  // Remembered for every later test, not just this one.
                  settings.setAutoAdvance(enable);
                  if (!enable) _advanceTimer?.cancel();
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        s(enable ? 'auto_advance_on' : 'auto_advance_off'),
                        style: const TextStyle(fontSize: 13),
                      ),
                      duration: const Duration(milliseconds: 1400),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 72),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  );
                },
                onFinish: _showFinishDialog,
                onExit: _showExitDialog,
              ),
              _QuestionNumberStrip(
                questions: _questions,
                currentIndex: _currentIndex,
                selectedAnswers: _selectedAnswers,
                incorrectIds: _incorrectIds,
                onSelect: _goToQuestion,
              ),
              Expanded(
                // NO SWIPING BETWEEN QUESTIONS. A finger that drifts while
                // tapping an answer turned the page instead, and the answer
                // landed on nothing. Moving is deliberate now: the number
                // strip above, or Oldingi / Keyingi below.
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    _precacheAround(index);
                  },
                  itemBuilder: (context, index) {
                    return _QuestionCard(
                      question: _questions[index],
                      uiLang: uiLang,
                      questionLang: qLang,
                      selectedAnswer:
                          _selectedAnswers[_questions[index].globalId],
                      onSelect: (optionId) =>
                          _selectAnswer(_questions[index], optionId, qLang),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Prev / explanation / next in the thumb's reach. The explanation used
        // to float in a corner and, on a 320 dp phone, sat on top of the
        // third answer.
        bottomNavigationBar: _QuestionNavBar(
          isFirst: _currentIndex == 0,
          isLast: _currentIndex == _questions.length - 1,
          prevLabel: s('prev_question'),
          nextLabel: s('next_question'),
          finishLabel: s('finish'),
          explanationLabel: _questions[_currentIndex].hasIzoh
              ? s('explanation_title')
              : null,
          // A calm hint, not a pop-up: after a wrong answer, a free user sees
          // that the explanation is what PRO adds.
          explanationIsPro:
              !context.watch<SubscriptionProvider>().isPro,
          explanationHighlighted: _incorrectIds.contains(
            _questions[_currentIndex].globalId,
          ),
          onPrev: () => _goToQuestion(_currentIndex - 1),
          onNext: () => _goToQuestion(_currentIndex + 1),
          onFinish: _showFinishDialog,
          onExplanation: () => _showExplanationSheet(
            context,
            question: _questions[_currentIndex],
            lang: qLang,
            uiLang: uiLang,
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final String uiLang;
  final String questionLang;
  final int? selectedAnswer;
  final ValueChanged<int> onSelect;

  const _QuestionCard({
    required this.question,
    required this.uiLang,
    required this.questionLang,
    this.selectedAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.getOptions(questionLang);
    final isAnswered = selectedAnswer != null;
    // Only the question and its answers scale — see SettingsProvider.
    final scale = context.watch<SettingsProvider>().scale;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // NO "Savol 3 / 20" CHIP HERE. The number strip above already shows
          // where the user is and how many questions there are, in a form they
          // can also act on. A second, non-interactive copy of the same fact
          // only pushed the question itself further down the screen.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.card(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border(context)),
              boxShadow: AppTheme.isDark(context)
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Text(
              question.getText(questionLang),
              style: TextStyle(
                fontSize: 17 * scale,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: AppTheme.textP(context),
              ),
            ),
          ),
          if (question.mediaUrl != null && question.mediaUrl!.isNotEmpty) ...[
            const SizedBox(height: 14),
            QuestionImage(
              fileName: question.mediaUrl!,
              zoomLabel: AppStrings.get('zoom_image', uiLang),
              onTap: () => ImageLightbox.show(
                context,
                fileName: question.mediaUrl!,
                uiLang: uiLang,
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...List.generate(options.length, (i) {
            final isSelected = selectedAnswer == options[i].id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnswerOptionTile(
                // F1..F6, not A..D: this is how the official exam program
                // labels its answers, and matching it is the point of the
                // whole app — the keys should already look familiar on the
                // day it matters. Same labels as the Real Exam screen.
                letter: 'F${i + 1}',
                text: options[i].getText(questionLang),
                scale: scale,
                isSelected: isSelected,
                isAnswered: isAnswered,
                isCorrect: options[i].isCorrect,
                // Spoken outcome. Until this existed the result of an answer
                // was carried by colour alone, so a screen-reader user was
                // told which option they had picked but never whether it was
                // right (docs/MOBILE-CONTENT-PROMPT.md §7.4).
                statusLabel: !isAnswered
                    ? null
                    : options[i].isCorrect
                    ? AppStrings.get('a11y_answer_correct', uiLang)
                    : isSelected
                    ? AppStrings.get('a11y_answer_incorrect', uiLang)
                    : null,
                onTap: isAnswered ? null : () => onSelect(options[i].id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;

  /// Question-text scale from [SettingsProvider]. Only the answer's own text
  /// grows — the letter chip and the icons stay put, so a large setting never
  /// pushes the row out of shape.
  final double scale;

  /// Announced after the outcome is known ("correct answer" / "your answer,
  /// wrong"). Null while the question is unanswered, and for the other
  /// options once it is — they carry no outcome worth reading out.
  final String? statusLabel;

  final VoidCallback? onTap;

  const _AnswerOptionTile({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    this.scale = 1.0,
    this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppTheme.card(context);
    Color borderColor = AppTheme.border(context);
    Color textColor = AppTheme.textP(context);
    IconData? trailingIcon;
    Color? iconColor;

    if (isAnswered) {
      if (isCorrect) {
        bgColor = AppTheme.success.withValues(alpha: 0.12);
        borderColor = AppTheme.success.withValues(alpha: 0.5);
        textColor = AppTheme.success;
        trailingIcon = Icons.check_circle_rounded;
        iconColor = AppTheme.success;
      } else if (isSelected) {
        bgColor = AppTheme.error.withValues(alpha: 0.12);
        borderColor = AppTheme.error.withValues(alpha: 0.5);
        textColor = AppTheme.error;
        trailingIcon = Icons.cancel_rounded;
        iconColor = AppTheme.error;
      }
    }

    return Semantics(
      button: true,
      enabled: onTap != null,
      // The selected state was previously conveyed by background colour only,
      // which a screen reader cannot see.
      selected: isSelected,
      value: statusLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: isAnswered && isCorrect
                        ? AppTheme.blueGradient
                        : null,
                    color: isAnswered && isCorrect
                        ? null
                        : AppTheme.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: isAnswered && isCorrect
                            ? Colors.white
                            : AppTheme.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      height: 1.45,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  Icon(trailingIcon, color: iconColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar: exit, timer, auto-advance, finish.
/// One square control in the test toolbar.
///
/// Every button up here is the same shape and size — a tinted rounded square
/// with a matching border. Auto-advance and finish used to be bare
/// `IconButton`s among four framed ones, which made them read as decoration
/// rather than controls.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final bool filled;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: filled ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withValues(alpha: filled ? 0.55 : 0.25),
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

class _TestToolbar extends StatelessWidget {
  final ValueListenable<int> timeLeft;
  final bool countUp;
  final bool autoAdvance;
  final bool isCurrentSaved;
  final String autoAdvanceTooltip;
  final String finishTooltip;
  final String exitTooltip;
  final String saveTooltip;
  final VoidCallback onToggleAutoAdvance;
  final VoidCallback onToggleSave;
  final VoidCallback onFinish;
  final VoidCallback onExit;

  const _TestToolbar({
    required this.timeLeft,
    required this.countUp,
    required this.autoAdvance,
    required this.isCurrentSaved,
    required this.autoAdvanceTooltip,
    required this.finishTooltip,
    required this.exitTooltip,
    required this.saveTooltip,
    required this.onToggleAutoAdvance,
    required this.onToggleSave,
    required this.onFinish,
    required this.onExit,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.close_rounded,
            color: AppTheme.error,
            tooltip: exitTooltip,
            filled: true,
            onTap: onExit,
          ),
          const SizedBox(width: 8),
          // The clock sits on the LEFT, next to the exit button. On the right
          // it was the thing a right-handed thumb covered, and glancing at the
          // time is the single most frequent look away from the question.
          ValueListenableBuilder<int>(
            valueListenable: timeLeft,
            builder: (context, seconds, _) {
              final timerColor = countUp
                  ? AppTheme.blue
                  : (seconds < 60
                        ? AppTheme.error
                        : (seconds < 300 ? AppTheme.orange : AppTheme.blue));
              return Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: timerColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 16, color: timerColor),
                    const SizedBox(width: 5),
                    Text(
                      _formatTime(seconds),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                        fontSize: 14.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          _ToolbarButton(
            icon: isCurrentSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: isCurrentSaved ? AppTheme.orange : AppTheme.blue,
            tooltip: saveTooltip,
            filled: isCurrentSaved,
            onTap: onToggleSave,
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: autoAdvance
                ? Icons.play_circle_rounded
                : Icons.play_circle_outline_rounded,
            color: autoAdvance ? AppTheme.blue : AppTheme.textM(context),
            tooltip: autoAdvanceTooltip,
            filled: autoAdvance,
            onTap: onToggleAutoAdvance,
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
            tooltip: finishTooltip,
            filled: true,
            onTap: onFinish,
          ),
        ],
      ),
    );
  }
}

/// Oldingi · Izoh · Keyingi — the only way between questions now that the
/// page no longer swipes. Every target is at least 48 dp tall.
class _QuestionNavBar extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final String prevLabel;
  final String nextLabel;
  final String finishLabel;

  /// Null when the current question has no explanation.
  final String? explanationLabel;
  final bool explanationIsPro;
  final bool explanationHighlighted;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onExplanation;

  const _QuestionNavBar({
    required this.isFirst,
    required this.isLast,
    required this.prevLabel,
    required this.nextLabel,
    required this.finishLabel,
    required this.explanationLabel,
    required this.explanationIsPro,
    required this.explanationHighlighted,
    required this.onPrev,
    required this.onNext,
    required this.onFinish,
    required this.onExplanation,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final gold = dark ? AppTheme.proBorder : AppTheme.proIcon;
    final teaser = explanationIsPro && explanationHighlighted;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        border: Border(top: BorderSide(color: AppTheme.hairline(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: _NavButton(
                  label: prevLabel,
                  leading: Icons.chevron_left_rounded,
                  onTap: isFirst ? null : onPrev,
                ),
              ),
              if (explanationLabel != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _NavButton(
                    label: explanationLabel!,
                    leadingWidget: explanationIsPro
                        ? CrownIcon(size: 16, color: gold)
                        : Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: AppTheme.brandAccent(context),
                          ),
                    background: teaser
                        ? (dark
                              ? AppTheme.proBorder.withValues(alpha: 0.1)
                              : AppTheme.proBg)
                        : null,
                    borderColor: teaser
                        ? AppTheme.proBorder.withValues(alpha: dark ? 0.4 : 1)
                        : null,
                    onTap: onExplanation,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _NavButton(
                  label: isLast ? finishLabel : nextLabel,
                  trailing: isLast ? null : Icons.chevron_right_rounded,
                  filled: true,
                  onTap: isLast ? onFinish : onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData? leading;
  final Widget? leadingWidget;
  final IconData? trailing;
  final bool filled;
  final Color? background;
  final Color? borderColor;
  final VoidCallback? onTap;

  const _NavButton({
    required this.label,
    this.leading,
    this.leadingWidget,
    this.trailing,
    this.filled = false,
    this.background,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final fg = filled ? Colors.white : AppTheme.brandAccent(context);
    final radius = BorderRadius.circular(AppTheme.radiusSm);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: filled
            ? AppTheme.brandFill(context)
            : (background ?? Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: filled
              ? BorderSide.none
              : BorderSide(color: borderColor ?? AppTheme.hairline(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingWidget != null) ...[
                    leadingWidget!,
                    const SizedBox(width: 6),
                  ] else if (leading != null)
                    Icon(leading, size: 22, color: fg),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  ),
                  if (trailing != null) Icon(trailing, size: 22, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionNumberStrip extends StatefulWidget {
  final List<Question> questions;
  final int currentIndex;
  final Map<String, int> selectedAnswers;
  final Set<String> incorrectIds;
  final ValueChanged<int> onSelect;

  const _QuestionNumberStrip({
    required this.questions,
    required this.currentIndex,
    required this.selectedAnswers,
    required this.incorrectIds,
    required this.onSelect,
  });

  @override
  State<_QuestionNumberStrip> createState() => _QuestionNumberStripState();
}

class _QuestionNumberStripState extends State<_QuestionNumberStrip> {
  static const double _itemExtent = 42; // 36 wide + 3 padding each side

  final _controller = ScrollController();

  @override
  void didUpdateWidget(_QuestionNumberStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _scrollToCurrent();
    }
  }

  /// Keeps the active number visible — on a 50-question variant the strip
  /// used to stay parked at question 1 while the user swiped ahead.
  void _scrollToCurrent() {
    if (!_controller.hasClients) return;
    final viewport = _controller.position.viewportDimension;
    final target =
        (widget.currentIndex * _itemExtent) -
        (viewport / 2) +
        (_itemExtent / 2);
    _controller.animateTo(
      target.clamp(
        _controller.position.minScrollExtent,
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions;
    final currentIndex = widget.currentIndex;
    final selectedAnswers = widget.selectedAnswers;
    final incorrectIds = widget.incorrectIds;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          final isAnswered = selectedAnswers.containsKey(q.globalId);
          final isIncorrect = incorrectIds.contains(q.globalId);
          final isCurrent = index == currentIndex;

          Color bgColor;
          Color textColor;
          Border? border;

          if (isCurrent) {
            bgColor = AppTheme.blue;
            textColor = Colors.white;
          } else if (isIncorrect) {
            bgColor = AppTheme.error.withValues(alpha: 0.15);
            textColor = AppTheme.error;
            border = Border.all(color: AppTheme.error.withValues(alpha: 0.4));
          } else if (isAnswered) {
            bgColor = AppTheme.success.withValues(alpha: 0.15);
            textColor = AppTheme.success;
            border = Border.all(color: AppTheme.success.withValues(alpha: 0.4));
          } else {
            bgColor = AppTheme.card(context);
            textColor = AppTheme.textM(context);
            border = Border.all(color: AppTheme.border(context));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => widget.onSelect(index),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(9),
                  border: border,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DialogStatRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DialogStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textS(context))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
