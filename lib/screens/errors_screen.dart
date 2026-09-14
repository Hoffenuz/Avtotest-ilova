import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/storage_service.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_lightbox.dart';
import '../widgets/premium_access_gate.dart';
import '../widgets/question_image.dart';
import 'test_screen.dart';

/// "Xato savollarim" and the drill built on it ("Xatolar ustida ishlash").
///
/// PRO ONLY, to match the website: `/xatolarim` and `/xatolar-testi` are both
/// premium there (docs/MOBILE-CONTENT-PROMPT.md §3 and §4), while the app was
/// serving them to everyone. That divergence also undercut the paywall from
/// the other side — a free user could reach the whole bank a few questions at
/// a time by getting them wrong on purpose.
///
/// Saved Questions is deliberately NOT gated the same way: the site asks only
/// for a login there, and this file is not the place to tighten that.
class ErrorsScreen extends StatelessWidget {
  final bool embedded;
  const ErrorsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return PremiumAccessGate(
      featureTitle: AppStrings.get('my_errors', lang),
      child: _ErrorsBody(embedded: embedded),
    );
  }
}

class _ErrorsBody extends StatefulWidget {
  final bool embedded;
  const _ErrorsBody({this.embedded = false});

  @override
  State<_ErrorsBody> createState() => _ErrorsScreenState();
}

class _ErrorsScreenState extends State<_ErrorsBody> {
  List<Question> _errorQuestions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  Future<void> _loadErrors() async {
    final errorIds = await StorageService.getErrorQuestions();
    if (!mounted) return;
    if (errorIds.isEmpty) {
      setState(() {
        _errorQuestions = [];
        _loading = false;
      });
      return;
    }
    final idSet = errorIds.toSet();
    final allQuestions = await QuestionService.loadAllQuestions();
    final errors = allQuestions
        .where((q) => idSet.contains(q.globalId))
        .toList();
    if (!mounted) return;
    setState(() {
      _errorQuestions = errors;
      _loading = false;
    });
  }

  /// Re-runs the user's own mistakes as a practice test — the mistakes list
  /// was read-only, so there was no way to actually drill them.
  void _practiceErrors(String lang) {
    if (_errorQuestions.isEmpty) return;
    final questions = List<Question>.from(_errorQuestions);
    final title = AppStrings.get('my_errors', lang);
    Navigator.push(
      context,
      AppTheme.slideRoute(
        TestScreen(
          title: title,
          loadQuestions: () async => questions,
          testType: 'practice',
          testLabel: title,
          timeLimitMinutes: questions.length * 2,
          questionLang: lang,
        ),
      ),
    ).then((_) => _loadErrors());
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(s('my_errors')),
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
        actions: [
          if (_errorQuestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(s('clear_errors_title')),
                      content: Text(s('clear_errors_msg')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(s('no')),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(s('yes')),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await StorageService.clearErrorQuestions();
                    setState(() => _errorQuestions.clear());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppTheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s('clear'),
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.blue))
          : _errorQuestions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 40,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s('no_errors'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textP(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s('no_errors_sub'),
                    style: TextStyle(color: AppTheme.textM(context)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _practiceErrors(lang),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(s('practice_errors')),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 20,
                        color: AppTheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_errorQuestions.length} ${s('total_errors')}',
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _errorQuestions.length,
                    itemBuilder: (context, index) {
                      final q = _errorQuestions[index];
                      return _ErrorQuestionCard(
                        index: index,
                        question: q,
                        lang: lang,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ErrorQuestionCard extends StatefulWidget {
  final int index;
  final Question question;
  final String lang;

  const _ErrorQuestionCard({
    required this.index,
    required this.question,
    required this.lang,
  });

  @override
  State<_ErrorQuestionCard> createState() => _ErrorQuestionCardState();
}

class _ErrorQuestionCardState extends State<_ErrorQuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final options = widget.question.getOptions(widget.lang);
    final correct = options.where((o) => o.isCorrect).firstOrNull;
    String s(String k) => AppStrings.get(k, widget.lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDeco(
        context,
        b: Border.all(color: AppTheme.error.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.question.getText(widget.lang),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppTheme.textP(context),
                          ),
                          maxLines: _expanded ? null : 3,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                        ),
                        if (correct != null && !_expanded) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                            child: Text(
                              '${s('correct_answer')}: ${correct.getText(widget.lang)}',
                              style: const TextStyle(
                                color: AppTheme.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textM(context),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppTheme.border(context)),
                  const SizedBox(height: 6),
                  // THE PICTURE WAS MISSING ENTIRELY. Half the questions a
                  // person gets wrong are intersection or sign diagrams, and
                  // without the drawing the review shows a question that
                  // cannot be answered — "which car goes first?" over nothing.
                  if (widget.question.mediaUrl != null &&
                      widget.question.mediaUrl!.isNotEmpty) ...[
                    QuestionImage(
                      fileName: widget.question.mediaUrl!,
                      maxHeight: 190,
                      zoomLabel: AppStrings.get('zoom_image', widget.lang),
                      onTap: () => ImageLightbox.show(
                        context,
                        fileName: widget.question.mediaUrl!,
                        uiLang: widget.lang,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    '${s('all_options')}:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textM(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(options.length, (i) {
                    final opt = options[i];
                    final isCorrectOpt = opt.isCorrect;
                    Color optBg = Colors.transparent;
                    Color optBorder = AppTheme.border(context);
                    Color optText = AppTheme.textS(context);
                    IconData? optIcon;

                    if (isCorrectOpt) {
                      optBg = AppTheme.success.withValues(alpha: 0.08);
                      optBorder = AppTheme.success.withValues(alpha: 0.3);
                      optText = AppTheme.success;
                      optIcon = Icons.check_circle_rounded;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: optBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: optBorder),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${String.fromCharCode(65 + i)}. ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: optText,
                              fontSize: 13,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              opt.getText(widget.lang),
                              style: TextStyle(fontSize: 13, color: optText),
                            ),
                          ),
                          if (optIcon != null)
                            Icon(optIcon, size: 18, color: optText),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
