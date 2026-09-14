import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/site_content.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/site_content_service.dart';
import '../theme/app_theme.dart';

/// "Avtodrom" — the penalty-point table of the practical exam, graded into
/// minor / medium / gross mistakes.
///
/// Mirrors the website's `/avtodrom`. Content comes from
/// `assets/data/avtodrom.json`, generated from the site's
/// `src/lib/avtodromPenalties.ts` by `tools/gen_sections.mjs`.
class AvtodromScreen extends StatefulWidget {
  const AvtodromScreen({super.key});

  @override
  State<AvtodromScreen> createState() => _AvtodromScreenState();
}

class _AvtodromScreenState extends State<AvtodromScreen> {
  late Future<List<PenaltyGroup>> _groups;

  /// Severity reads as a colour ramp, deepening with the penalty.
  static const Map<PenaltyLevel, Color> _levelColors = {
    PenaltyLevel.kichik: Color(0xFFD97706), // amber
    PenaltyLevel.orta: Color(0xFFEA580C), // orange
    PenaltyLevel.qopol: Color(0xFFE11D48), // rose
  };

  @override
  void initState() {
    super.initState();
    _groups = SiteContentService.loadPenaltyGroups();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('avtodrom', lang))),
      body: FutureBuilder<List<PenaltyGroup>>(
        future: _groups,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.blue,
                strokeWidth: 2.5,
              ),
            );
          }
          final groups = snapshot.data ?? const <PenaltyGroup>[];
          if (groups.isEmpty) {
            return Center(
              child: Text(
                AppStrings.get('no_results', lang),
                style: TextStyle(color: AppTheme.textM(context)),
              ),
            );
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              // Shown for the same reason the website shows it: only the Latin
              // text is the official wording — the other two are this
              // project's translation, and a user comparing them against the
              // official document deserves to know that.
              if (lang != 'uz_lat') ...[
                _TranslationNote(lang: lang),
                const SizedBox(height: 14),
              ],
              for (final group in groups) ...[
                _GroupHeading(
                  group: group,
                  lang: lang,
                  color: _levelColors[group.level] ?? AppTheme.orange,
                ),
                const SizedBox(height: 8),
                for (final item in group.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PenaltyTile(
                      item: item,
                      lang: lang,
                      color: _levelColors[group.level] ?? AppTheme.orange,
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TranslationNote extends StatelessWidget {
  final String lang;
  const _TranslationNote({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppTheme.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.get('avtodrom_translation_note', lang),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeading extends StatelessWidget {
  final PenaltyGroup group;
  final String lang;
  final Color color;

  const _GroupHeading({
    required this.group,
    required this.lang,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            group.title.get(lang),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${group.items.length}',
            style: TextStyle(fontSize: 13, color: AppTheme.textM(context)),
          ),
        ],
      ),
    );
  }
}

class _PenaltyTile extends StatelessWidget {
  final PenaltyItem item;
  final String lang;
  final Color color;

  const _PenaltyTile({
    required this.item,
    required this.lang,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final note = item.note?.get(lang);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppTheme.cardDeco(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${item.no}.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textM(context),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.text.get(lang),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppTheme.textP(context),
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textM(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '${item.points} ${AppStrings.get('avtodrom_points', lang)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
