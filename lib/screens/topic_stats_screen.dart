import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/topic_stats_service.dart';
import '../theme/app_theme.dart';

/// "Which topics am I weak in" — accuracy per topic, worst first.
///
/// The results history could only say "17 of 20"; it could never say *what*
/// the three wrong ones had in common. This can, from data the app was
/// already in a position to record.
class TopicStatsScreen extends StatefulWidget {
  const TopicStatsScreen({super.key});

  @override
  State<TopicStatsScreen> createState() => _TopicStatsScreenState();
}

class _TopicStatsScreenState extends State<TopicStatsScreen> {
  late Future<List<TopicStat>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = TopicStatsService.compute();
  }

  /// Red below 60, amber to 80, green above — the same reading as the pass
  /// mark people already have in their heads (90% to pass the real exam, so
  /// anything under 80 is genuinely not ready).
  static Color _toneFor(int percent) {
    if (percent >= 80) return AppTheme.success;
    if (percent >= 60) return AppTheme.orange;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(title: Text(s('topic_stats'))),
      body: FutureBuilder<List<TopicStat>>(
        future: _rows,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.blue,
                strokeWidth: 2.5,
              ),
            );
          }

          final rows = snapshot.data ?? const <TopicStat>[];
          final withData = rows.where((r) => r.hasData).toList();

          if (withData.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      size: 44,
                      color: AppTheme.textM(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s('topic_stats_empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppTheme.textM(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final untouched = rows.where((r) => !r.hasData).toList();

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  s('topic_stats_hint'),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppTheme.textM(context),
                  ),
                ),
              ),
              for (final row in withData)
                _TopicStatRow(
                  row: row,
                  lang: lang,
                  tone: _toneFor(row.accuracyPercent),
                ),
              if (untouched.isNotEmpty) ...[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    s('topic_stats_untouched'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.textM(context),
                    ),
                  ),
                ),
                for (final row in untouched)
                  _UntouchedRow(row: row, lang: lang),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TopicStatRow extends StatelessWidget {
  final TopicStat row;
  final String lang;
  final Color tone;

  const _TopicStatRow({
    required this.row,
    required this.lang,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDeco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.topic.getName(lang),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textP(context),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  '${row.accuracyPercent}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tone,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: row.accuracy,
              backgroundColor: AppTheme.border(context),
              valueColor: AlwaysStoppedAnimation(tone),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${row.correct}/${row.attempts} · '
            '${row.answered}/${row.total} ${AppStrings.get('question', lang).toLowerCase()}',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textM(context)),
          ),
        ],
      ),
    );
  }
}

class _UntouchedRow extends StatelessWidget {
  final TopicStat row;
  final String lang;

  const _UntouchedRow({required this.row, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: Row(
        children: [
          Icon(
            Icons.radio_button_unchecked,
            size: 14,
            color: AppTheme.textM(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.topic.getName(lang),
              style: TextStyle(fontSize: 13.5, color: AppTheme.textM(context)),
            ),
          ),
          Text(
            '${row.total}',
            style: TextStyle(fontSize: 12, color: AppTheme.textM(context)),
          ),
        ],
      ),
    );
  }
}
