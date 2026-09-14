import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tab_visibility.dart';
import 'test_screen.dart';

class SavedQuestionsScreen extends StatefulWidget {
  final bool embedded;
  final int? tabIndex;

  const SavedQuestionsScreen({super.key, this.embedded = false, this.tabIndex});

  @override
  State<SavedQuestionsScreen> createState() => _SavedQuestionsScreenState();
}

class _SavedQuestionsScreenState extends State<SavedQuestionsScreen>
    with AutomaticKeepAliveClientMixin {
  List<Question> _savedQuestions = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  bool _isVisible() {
    if (widget.tabIndex == null) return true;
    final tabs = TabVisibility.maybeOf(context);
    if (tabs == null) return true;
    return tabs.isTabActive(widget.tabIndex!);
  }

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isVisible()) _loadSaved();
  }

  Future<void> _loadSaved() async {
    final ids = await StorageService.getSavedQuestions();
    if (ids.isEmpty) {
      if (!mounted) return;
      setState(() {
        _savedQuestions = [];
        _loading = false;
      });
      return;
    }

    final questions = await QuestionService.loadQuestionsByGlobalIds(ids);
    if (!mounted) return;
    setState(() {
      _savedQuestions = questions;
      _loading = false;
    });
  }

  Future<void> _removeQuestion(Question question) async {
    await StorageService.removeSavedQuestion(question.globalId);
    setState(() {
      _savedQuestions.removeWhere((q) => q.globalId == question.globalId);
    });
  }

  Future<void> _clearAll(String lang) async {
    String s(String k) => AppStrings.get(k, lang);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('clear_saved_title')),
        content: Text(s('clear_saved_msg')),
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
    if (ok != true || !mounted) return;
    await StorageService.clearSavedQuestions();
    setState(() => _savedQuestions.clear());
  }

  void _openSingle(Question question, String lang) {
    String s(String k) => AppStrings.get(k, lang);
    Navigator.push(
      context,
      AppTheme.slideRoute(
        TestScreen(
          title: '${s('question')} ${question.idLabel}',
          loadQuestions: () async => [question],
          testType: 'practice',
          testLabel: '${s('saved_question')} ${question.idLabel}',
          timeLimitMinutes: 10,
          questionLang: lang,
        ),
      ),
    ).then((_) => _loadSaved());
  }

  void _openAll(String lang) {
    if (_savedQuestions.isEmpty) return;
    final questions = List<Question>.from(_savedQuestions);
    String s(String k) => AppStrings.get(k, lang);
    Navigator.push(
      context,
      AppTheme.slideRoute(
        TestScreen(
          title: s('saved_tests'),
          loadQuestions: () async => questions,
          testType: 'practice',
          testLabel: s('saved_tests'),
          timeLimitMinutes: questions.length * 2,
          questionLang: lang,
        ),
      ),
    ).then((_) => _loadSaved());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(s('saved_tests')),
        automaticallyImplyLeading: !widget.embedded,
        actions: [
          if (_savedQuestions.isNotEmpty)
            IconButton(
              tooltip: s('clear'),
              onPressed: () => _clearAll(lang),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.blue))
          : _savedQuestions.isEmpty
          ? _EmptySavedState(lang: lang)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openAll(lang),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(s('run_saved_tests')),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.blue.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bookmark_rounded,
                          size: 20,
                          color: AppTheme.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_savedQuestions.length} ${s('saved_count')}',
                          style: const TextStyle(
                            color: AppTheme.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.blue,
                    onRefresh: _loadSaved,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(16),
                      itemCount: _savedQuestions.length,
                      itemBuilder: (context, index) {
                        final q = _savedQuestions[index];
                        return _SavedQuestionTile(
                          question: q,
                          lang: lang,
                          onTap: () => _openSingle(q, lang),
                          onRemove: () => _removeQuestion(q),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptySavedState extends StatelessWidget {
  final String lang;
  const _EmptySavedState({required this.lang});

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, lang);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 40,
                color: AppTheme.blue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s('no_saved'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textP(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s('no_saved_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textM(context),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedQuestionTile extends StatelessWidget {
  final Question question;
  final String lang;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedQuestionTile({
    required this.question,
    required this.lang,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final text = question.getText(lang);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDeco(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.blueGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${question.jsonId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID ${question.idLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: AppTheme.textP(context),
                        ),
                      ),
                      if (question.mediaUrl != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 14,
                              color: AppTheme.textM(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.get('has_image', lang),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textM(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.bookmark_remove_rounded,
                    color: AppTheme.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
