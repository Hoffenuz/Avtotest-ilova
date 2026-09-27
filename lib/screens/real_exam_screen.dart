// ============================================================================
// RealExamScreen — "Real imtihon"
// ----------------------------------------------------------------------------
// Mirrors the website's `src/components/RealExamInterface.tsx`: the point of
// this screen is that what the user meets on exam day is something they have
// already practised on, so it copies the official program's layout rather than
// the app's own.
//
// DELIBERATE DIFFERENCES FROM EVERY OTHER TEST SCREEN
// (docs/MOBILE-CONTENT-PROMPT.md §3.1):
//   * NO EXPLANATION — an exam never explains itself. Not after an answer, not
//     on the results screen.
//   * NO LANGUAGE SWITCH — the language is fixed when the exam starts.
//   * No saving a question, no auto-advance toggle, no topic controls.
//   * Answering jumps to the next UNANSWERED question by itself, and answering
//     the last one ends the exam by itself.
//
// WHY THE COLOURS ARE HARD-CODED:
//   This screen does not follow the app's light/dark theme. It reproduces one
//   specific program's appearance, so it has to look the SAME in both — a
//   requirement the prompt calls out explicitly. Reaching for AppTheme here
//   would be the bug, not the fix.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../services/test_results_service.dart';
import '../services/test_session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_lightbox.dart';
import '../widgets/question_image.dart';
import 'result_screen.dart';

/// Exam shape, matching `src/pages/RealImtihon.tsx`.
const int _questionCount = 20;
const Duration _timeLimit = Duration(minutes: 25);

/// How long the answer's colour stays on screen before moving on. Long enough
/// to register green/red, short enough not to feel like waiting.
const Duration _advanceDelay = Duration(milliseconds: 900);
const Duration _finishDelay = Duration(milliseconds: 1200);

/// Answer key captions, as the official program labels them.
const List<String> _fKeys = ['F1', 'F2', 'F3', 'F4', 'F5', 'F6'];

// ─────────────────────────────────────────────────── exam palette (fixed)
const Color _backdrop = Color(0xFF081A33);
const Color _panel = Color(0xFF0A1020);
const Color _bar = Color(0xFF060B16);
const Color _questionBg = Color(0xFF8F1A24);
const Color _questionBorder = Color(0xFFA8323D);

/// Answer tones. The panel greys were picked for contrast: the program's own
/// light grey reached only ~2.9:1 against white text, well under the 4.5:1
/// floor, and the text looked washed out. These clear 6:1.
const Color _keyIdle = Color(0xFF2C6BA0);
const Color _textIdle = Color(0xFF3F4D61);
const Color _keyRight = Color(0xFF125C25);
const Color _textRight = Color(0xFF177A34);
const Color _keyWrong = Color(0xFF7F1A1A);
const Color _textWrong = Color(0xFFA52626);

const Color _stripIdle = Color(0xFF3A4454);
const Color _stripRight = Color(0xFF1F9D4D);
const Color _stripWrong = Color(0xFFCC2B2B);

/// Picture frame. Deliberately faint — the frame should be noticeable without
/// competing with the illustration inside it.
const Color _imageFrame = Color(0xFF0E1626);
const Color _imageFrameBorder = Color(0xFF283245);

class RealExamScreen extends StatefulWidget {
  const RealExamScreen({super.key});

  @override
  State<RealExamScreen> createState() => _RealExamScreenState();
}

class _RealExamScreenState extends State<RealExamScreen> {
  List<Question> _questions = const [];
  bool _loading = true;
  String? _error;
  bool _finished = false;

  /// Pinned once, when the exam starts. Reading the provider later would let a
  /// language change mid-exam re-order the answers under the user, because the
  /// three translations of a question list their options in different orders.
  late String _lang;
  bool _langPinned = false;

  int _current = 0;

  /// `globalId` → chosen option id.
  final Map<String, int> _selected = {};
  final Set<String> _incorrectIds = {};

  /// Asked for when the exam starts, needed only when it is saved.
  Future<String?>? _sessionId;
  bool _isPro = false;

  /// Ticks alone so the clock does not rebuild the question and its answers
  /// once a second — the same reason [TestScreen] keeps its timer separate.
  late final ValueNotifier<int> _secondsLeft = ValueNotifier<int>(
    _timeLimit.inSeconds,
  );
  Timer? _timer;
  Timer? _advanceTimer;
  Timer? _finishTimer;
  DateTime _startedAt = DateTime.now();

  final ScrollController _stripController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _advanceTimer?.cancel();
    _finishTimer?.cancel();
    _secondsLeft.dispose();
    _stripController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_langPinned) {
      _lang = context.read<LanguageProvider>().lang;
      _langPinned = true;
    }
    final sub = context.read<SubscriptionProvider>();
    // Wait for a first answer if there is none yet: reading `isPro` before the
    // RPC has replied made a subscriber's exam draw from the free pool just
    // because they opened it quickly after launch. Already-known state is not
    // re-fetched, so this costs nothing on the common path.
    if (sub.isUnknown) await sub.refreshIfUnknown();
    if (!mounted) return;
    _isPro = sub.isPro;

    setState(() {
      _loading = true;
      _error = null;
      _finished = false;
      _selected.clear();
      _incorrectIds.clear();
      _current = 0;
    });

    try {
      final questions = await QuestionService.loadExamQuestions(
        isPro: _isPro,
        count: _questionCount,
      );
      if (!mounted) return;
      if (questions.isEmpty) {
        setState(() {
          _loading = false;
          _error = AppStrings.get('no_questions', _lang);
        });
        return;
      }

      // The server session is best-effort: a Real Exam is open to everyone
      // (docs/MOBILE-CONTENT-PROMPT.md §3), so no session must never mean no
      // exam, and the exam does not wait for it either — it is requested
      // alongside and only needed when the result is saved.
      _sessionId = TestSessionService.startSession(
        variant: TestSessionService.realExamVariant,
        questionSource: _questionSource,
        isPremium: _isPro,
      ).then((session) => session.sessionId);

      setState(() {
        _questions = questions;
        _loading = false;
        _startedAt = DateTime.now();
      });
      _secondsLeft.value = _timeLimit.inSeconds;
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// The website records which bank the attempt was drawn from; using the same
  /// file names keeps app and web rows comparable in `test_results`.
  String get _questionSource {
    final suffix = switch (_lang) {
      'uz_cyr' => 'uz-cyr',
      'ru' => 'ru',
      _ => 'uz-lat',
    };
    return _isPro ? 'barcha-$suffix.json' : 'free-$suffix.json';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final left = _secondsLeft.value - 1;
      _secondsLeft.value = left < 0 ? 0 : left;
      if (left <= 0) {
        timer.cancel();
        _finish();
      }
    });
  }

  Question get _question => _questions[_current];

  bool get _isAnswered => _selected.containsKey(_question.globalId);

  void _answer(int optionId) {
    final question = _question;
    if (_selected.containsKey(question.globalId)) return;

    final options = question.getOptions(_lang);
    final picked = options.firstWhere((o) => o.id == optionId);

    setState(() {
      _selected[question.globalId] = optionId;
      if (!picked.isCorrect) _incorrectIds.add(question.globalId);
    });

    // Answering the last remaining question ends the exam by itself, as the
    // official program does. The delay is so the final answer's colour is
    // actually seen before the results appear.
    if (_selected.length >= _questions.length) {
      _finishTimer?.cancel();
      _finishTimer = Timer(_finishDelay, _finish);
      return;
    }

    _advanceTimer?.cancel();
    _advanceTimer = Timer(_advanceDelay, () {
      if (!mounted) return;
      final next = _nextUnanswered(_current);
      if (next != -1) _goTo(next);
    });
  }

  /// Next question with no answer yet, wrapping around. Deliberately not
  /// `_current + 1`: after going back to fill in a skipped question, moving on
  /// should not land on one that is already done.
  int _nextUnanswered(int from) {
    for (var step = 1; step <= _questions.length; step++) {
      final i = (from + step) % _questions.length;
      if (!_selected.containsKey(_questions[i].globalId)) return i;
    }
    return -1;
  }

  void _goTo(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _current = index);
    _scrollStripToCurrent();
  }

  /// Keeps the active number visible in the single-row strip. Twenty numbers
  /// do not fit across a phone, and a user who cannot see where they are stops
  /// trusting the strip.
  void _scrollStripToCurrent() {
    if (!_stripController.hasClients) return;
    const itemExtent = 34.0; // 28 wide + 6 gap
    final viewport = _stripController.position.viewportDimension;
    final target = (_current * itemExtent) - (viewport / 2) + (itemExtent / 2);
    _stripController.animateTo(
      target.clamp(0.0, _stripController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _finish() {
    // The countdown expiring, auto-advance running out of questions and the
    // confirm dialog can all land in the same frame.
    if (_finished || !mounted) return;
    _finished = true;
    _timer?.cancel();
    _advanceTimer?.cancel();
    _finishTimer?.cancel();

    final correct = _questions.where((q) {
      final picked = _selected[q.globalId];
      if (picked == null) return false;
      final answers = q.getOptions(_lang).where((o) => o.isCorrect);
      return answers.isNotEmpty && answers.first.id == picked;
    }).length;

    final result = TestResult(
      type: 'exam',
      testKey: _questionSource,
      label: AppStrings.get('real_exam', _lang),
      totalQuestions: _questions.length,
      correctAnswers: correct,
      timeSpentSeconds: DateTime.now().difference(_startedAt).inSeconds,
      date: DateTime.now(),
      isCompleted: _selected.length >= _questions.length,
    );

    final session = _sessionId;
    if (session == null) {
      TestResultsService.save(result);
    } else {
      session.then((id) => TestResultsService.save(result, sessionId: id));
    }

    Navigator.pushReplacement(
      context,
      AppTheme.fadeRoute(
        ResultScreen(
          result: result,
          questions: _questions,
          selectedAnswers: _selected,
          incorrectIds: _incorrectIds,
          testTitle: AppStrings.get('real_exam', _lang),
          // No `retakeLoadQuestions`: that path opens TestScreen, which shows
          // explanations. A retry has to come back here, with a new draw and a
          // new server session.
          onRetake: () => Navigator.pushReplacement(
            context,
            AppTheme.fadeRoute(const RealExamScreen()),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('real_exam_exit_title', _lang)),
        content: Text(AppStrings.get('real_exam_exit_msg', _lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get('cancel', _lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.get('confirm', _lang)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _finish();
  }

  @override
  Widget build(BuildContext context) {
    // The exam owns the whole screen and paints its own light-on-dark chrome,
    // so the status bar icons are forced light regardless of the app theme.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _bar,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_loading || _error != null || _questions.isEmpty) {
            Navigator.pop(context);
          } else {
            _confirmExit();
          }
        },
        child: Scaffold(
          backgroundColor: _backdrop,
          body: SafeArea(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      );
    }

    if (_error != null || _questions.isEmpty) {
      final lang = _langPinned ? _lang : 'uz_lat';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? AppStrings.get('no_questions', lang),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFFC7C7), fontSize: 15),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppStrings.get('back', lang),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: _panel,
      child: Column(
        children: [
          _buildHeader(),
          _buildQuestionBanner(),
          Expanded(child: _buildAnswerArea()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _bar,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.get('real_exam', _lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_selected.length}/${_questions.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _confirmExit,
            tooltip: AppStrings.get('finish', _lang),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _questionBg,
          border: Border.all(color: _questionBorder),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          _question.getText(_lang),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerArea() {
    final question = _question;
    final options = question.getOptions(_lang);
    final answered = _isAnswered;
    final picked = _selected[question.globalId];

    return ListView(
      padding: const EdgeInsets.all(8),
      physics: const BouncingScrollPhysics(),
      children: [
        // The picture comes BEFORE the answers on a phone: the eye should
        // land on it straight after reading the question.
        if (question.mediaUrl != null && question.mediaUrl!.isNotEmpty) ...[
          QuestionImage(
            fileName: question.mediaUrl!,
            maxHeight: 200,
            // Fixed, like everything else here — the default frame colours
            // come from AppTheme and would make this screen change with the
            // app theme, which is exactly what it must not do.
            backgroundColor: _imageFrame,
            borderColor: _imageFrameBorder,
            zoomLabel: AppStrings.get('zoom_image', _lang),
            onTap: () => ImageLightbox.show(
              context,
              fileName: question.mediaUrl!,
              uiLang: _lang,
            ),
          ),
          const SizedBox(height: 10),
        ],
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ExamAnswer(
              caption: i < _fKeys.length ? _fKeys[i] : '${i + 1}',
              text: options[i].getText(_lang),
              answered: answered,
              isRight: options[i].isCorrect,
              isPicked: picked == options[i].id,
              statusLabel: !answered
                  ? null
                  : options[i].isCorrect
                  ? AppStrings.get('a11y_answer_correct', _lang)
                  : picked == options[i].id
                  ? AppStrings.get('a11y_answer_incorrect', _lang)
                  : null,
              onTap: answered ? null : () => _answer(options[i].id),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      color: _bar,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 28,
              child: ListView.separated(
                controller: _stripController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _questions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final answered = _selected[_questions[i].globalId];
                  Color tone = _stripIdle;
                  if (answered != null) {
                    tone = _incorrectIds.contains(_questions[i].globalId)
                        ? _stripWrong
                        : _stripRight;
                  }
                  return _StripNumber(
                    number: i + 1,
                    tone: tone,
                    isCurrent: i == _current,
                    label: '${AppStrings.get('question', _lang)} ${i + 1}',
                    onTap: () {
                      _advanceTimer?.cancel();
                      _goTo(i);
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: _secondsLeft,
            builder: (context, seconds, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _formatClock(seconds),
                style: const TextStyle(
                  color: Colors.black,
                  fontFamily: 'monospace',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `H:MM:SS`, as the official program shows it. The hour is always 0 for a
  /// 25-minute exam, but it is on that screen, so it is on this one.
  static String _formatClock(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

class _ExamAnswer extends StatelessWidget {
  final String caption;
  final String text;
  final bool answered;
  final bool isRight;
  final bool isPicked;
  final String? statusLabel;
  final VoidCallback? onTap;

  const _ExamAnswer({
    required this.caption,
    required this.text,
    required this.answered,
    required this.isRight,
    required this.isPicked,
    this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color keyTone = _keyIdle;
    Color textTone = _textIdle;
    if (answered) {
      if (isRight) {
        keyTone = _keyRight;
        textTone = _textRight;
      } else if (isPicked) {
        keyTone = _keyWrong;
        textTone = _textWrong;
      } else {
        // Faded, not hidden: the untaken options stay readable so the user can
        // still compare them against the right one.
        keyTone = _keyIdle.withValues(alpha: 0.4);
        textTone = _textIdle.withValues(alpha: 0.4);
      }
    }

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: isPicked,
      value: statusLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 44,
                    color: keyTone,
                    alignment: Alignment.center,
                    child: Text(
                      caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: textTone,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

class _StripNumber extends StatelessWidget {
  final int number;
  final Color tone;
  final bool isCurrent;
  final String label;
  final VoidCallback onTap;

  const _StripNumber({
    required this.number,
    required this.tone,
    required this.isCurrent,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isCurrent,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone,
            borderRadius: BorderRadius.circular(3),
            border: isCurrent
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
