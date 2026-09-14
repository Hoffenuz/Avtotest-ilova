import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/site_content.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/site_content_service.dart';
import '../theme/app_theme.dart';

/// "Yodlash kerak" — the numbers that come up in the exam and are awkward to
/// remember: speed limits, distances, dimensions, tread depth and so on.
///
/// Mirrors the website's `/yodlash-kerak`. Content comes from
/// `assets/data/yodlash.json`, generated from the site's
/// `src/lib/yodlashRaqamlari.ts` by `tools/gen_sections.mjs`.
///
/// READING ORDER IS PART OF THE CONTENT: every row says WHAT first and the
/// number second ("M1 yengil — 10 gradus", never "10 gradus — M1 yengil"), so
/// a value is never left hanging without the thing it belongs to. The layout
/// below keeps that order.
class MemorizeScreen extends StatefulWidget {
  const MemorizeScreen({super.key});

  @override
  State<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends State<MemorizeScreen> {
  late Future<List<FactTopic>> _topics;

  /// Only one topic is open at a time — the nine of them together are ~52 rows
  /// and an all-open list is a wall of numbers nobody reads.
  int? _expanded = 0;

  static const List<Color> _accents = [
    Color(0xFFE11D48), // rose
    Color(0xFF0EA5E9), // sky
    Color(0xFF8B5CF6), // violet
    Color(0xFFF97316), // orange
    Color(0xFF06B6D4), // cyan
    Color(0xFFF59E0B), // amber
    Color(0xFF10B981), // emerald
    Color(0xFF6366F1), // indigo
    Color(0xFF14B8A6), // teal
  ];

  /// Icons in the same order the website assigns them per topic id.
  static const Map<String, IconData> _icons = {
    'tezlik': Icons.speed_rounded,
    'reaktsiya': Icons.timer_outlined,
    'toxtash': Icons.do_not_disturb_on_outlined,
    'avariya-belgisi': Icons.warning_amber_rounded,
    'gabarit': Icons.straighten_rounded,
    'yuk': Icons.inventory_2_outlined,
    'shatak': Icons.link_rounded,
    'shina': Icons.trip_origin_rounded,
    'rul-tormoz': Icons.build_outlined,
  };

  @override
  void initState() {
    super.initState();
    _topics = SiteContentService.loadFactTopics();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('memorize', lang))),
      body: FutureBuilder<List<FactTopic>>(
        future: _topics,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.blue,
                strokeWidth: 2.5,
              ),
            );
          }
          final topics = snapshot.data ?? const <FactTopic>[];
          if (topics.isEmpty) {
            return Center(
              child: Text(
                AppStrings.get('no_results', lang),
                style: TextStyle(color: AppTheme.textM(context)),
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: topics.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _TopicCard(
              topic: topics[i],
              lang: lang,
              accent: _accents[i % _accents.length],
              icon: _icons[topics[i].id] ?? Icons.info_outline_rounded,
              expanded: _expanded == i,
              onToggle: () =>
                  setState(() => _expanded = _expanded == i ? null : i),
            ),
          );
        },
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final FactTopic topic;
  final String lang;
  final Color accent;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;

  const _TopicCard({
    required this.topic,
    required this.lang,
    required this.accent,
    required this.icon,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDeco(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.title.get(lang),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textP(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            topic.subtitle.get(lang),
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.3,
                              color: AppTheme.textM(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textM(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in topic.groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              group.heading.get(lang),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final row in group.rows)
                      _FactRowTile(row: row, lang: lang, accent: accent),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FactRowTile extends StatelessWidget {
  final FactRow row;
  final String lang;
  final Color accent;

  const _FactRowTile({
    required this.row,
    required this.lang,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final label = row.label.get(lang);
    final unit = row.unit.get(lang);

    return Semantics(
      // Read as one sentence instead of three fragments.
      label: '$label — ${row.value} $unit',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: AppTheme.textS(context),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: row.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: accent.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
