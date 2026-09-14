import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../utils/text_search.dart';
import '../widgets/explanation_panel.dart';
import '../widgets/image_lightbox.dart';
import '../widgets/premium_access_gate.dart';
import '../widgets/question_image.dart';

/// "Savol qidirish" — free-text search across the whole question bank.
/// PRO only, matching the website's `/qidirish`.
class QuestionSearchScreen extends StatelessWidget {
  const QuestionSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return PremiumAccessGate(
      featureTitle: AppStrings.get('question_search', lang),
      child: const _QuestionSearchBody(),
    );
  }
}

class _QuestionSearchBody extends StatefulWidget {
  const _QuestionSearchBody();

  @override
  State<_QuestionSearchBody> createState() => _QuestionSearchBodyState();
}

class _QuestionSearchBodyState extends State<_QuestionSearchBody> {
  static const int _minQueryLength = 3;

  /// The bank is 1259 questions × 3 languages; a page of results is plenty to
  /// scan, and building all of them would make every keystroke expensive.
  static const int _maxResults = 60;

  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<Question> _all = const [];
  List<Question> _results = const [];
  bool _loading = true;
  String _query = '';

  /// One pre-folded haystack per question, in the language being searched.
  ///
  /// Folding on the fly meant lower-casing and running an apostrophe regex
  /// over 1259 questions AND their four-or-so answers each — roughly six
  /// thousand string rebuilds — on every debounced keystroke, on the UI
  /// thread. That is what made typing in this box stutter. It is built once
  /// per language instead, and rebuilt only if the language changes.
  List<String> _haystack = const [];
  String? _haystackLang;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await QuestionService.loadAllQuestions();
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
    });
  }

  void _ensureHaystack(String lang) {
    if (_haystackLang == lang && _haystack.length == _all.length) return;
    _haystack = [
      for (final q in _all)
        foldForSearch(
          '${q.getText(lang)} '
          '${q.getOptions(lang).map((o) => o.getText(lang)).join(' ')}',
        ),
    ];
    _haystackLang = lang;
  }

  void _onChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _search(raw);
    });
  }

  void _search(String raw) {
    final query = foldForSearch(raw.trim());
    if (query.length < _minQueryLength) {
      setState(() {
        _query = raw.trim();
        _results = const [];
      });
      return;
    }

    final lang = context.read<LanguageProvider>().lang;
    _ensureHaystack(lang);

    final matches = <Question>[];
    for (var i = 0; i < _all.length; i++) {
      if (_haystack[i].contains(query)) {
        matches.add(_all[i]);
        if (matches.length >= _maxResults) break;
      }
    }

    setState(() {
      _query = raw.trim();
      _results = matches;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(title: Text(s('question_search'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              autofocus: true,
              decoration: InputDecoration(
                hintText: s('question_search_hint'),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppTheme.textM(context),
                ),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _buildResults(lang, s)),
        ],
      ),
    );
  }

  Widget _buildResults(String lang, String Function(String) s) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.blue,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_query.length < _minQueryLength) {
      return _EmptyState(
        icon: Icons.search_rounded,
        message: s('question_search_empty'),
      );
    }

    if (_results.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        message: s('no_results'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_results.length}${_results.length >= _maxResults ? '+' : ''} '
                '${s('question_search_count')}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textM(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _results.length,
            itemBuilder: (context, i) =>
                _SearchResultCard(question: _results[i], lang: lang),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppTheme.textM(context)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textM(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatefulWidget {
  final Question question;
  final String lang;

  const _SearchResultCard({required this.question, required this.lang});

  @override
  State<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<_SearchResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final options = widget.question.getOptions(widget.lang);
    final correct = options.where((o) => o.isCorrect);
    String s(String k) => AppStrings.get(k, widget.lang);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDeco(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.question.getText(widget.lang),
                            maxLines: _expanded ? null : 3,
                            overflow: _expanded ? null : TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textP(context),
                            ),
                          ),
                          if (!_expanded && correct.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${s('correct_answer')}: '
                              '${correct.first.getText(widget.lang)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textM(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.question.mediaUrl != null &&
                      widget.question.mediaUrl!.isNotEmpty) ...[
                    QuestionImage(
                      fileName: widget.question.mediaUrl!,
                      maxHeight: 180,
                      zoomLabel: AppStrings.get('zoom_image', widget.lang),
                      onTap: () => ImageLightbox.show(
                        context,
                        fileName: widget.question.mediaUrl!,
                        uiLang: widget.lang,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  for (var i = 0; i < options.length; i++)
                    _OptionRow(
                      letter: String.fromCharCode(65 + i),
                      text: options[i].getText(widget.lang),
                      isCorrect: options[i].isCorrect,
                    ),
                  if (widget.question.hasIzoh) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: AppTheme.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s('explanation_title'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textM(context),
                          ),
                        ),
                      ],
                    ),
                    // Never rendered raw: the panel runs its own PRO +
                    // connectivity check, so a future caller cannot leak the
                    // explanation by forgetting one here.
                    ExplanationPanel(
                      question: widget.question,
                      lang: widget.lang,
                      uiLang: widget.lang,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;

  const _OptionRow({
    required this.letter,
    required this.text,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppTheme.success : AppTheme.textS(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.success.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isCorrect
              ? AppTheme.success.withValues(alpha: 0.3)
              : AppTheme.border(context),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$letter. ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color)),
          ),
          if (isCorrect)
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppTheme.success,
            ),
        ],
      ),
    );
  }
}
