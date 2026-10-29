import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// One official document or site the app's content rests on.
class OfficialSource {
  final String titleKey;
  final String subKey;
  final String url;
  const OfficialSource(this.titleKey, this.subKey, this.url);

  /// The address as people read it: no scheme, no trailing slash.
  String get shown => url
      .replaceFirst(RegExp(r'^https?://(www\.)?'), '')
      .replaceFirst(RegExp(r'/$'), '');
}

/// Where the questions, rules and signs come from.
///
/// Google Play asks an app that carries government information to link the
/// original source and to say it is not a government service. Every address
/// here was opened and read; add one only after doing the same.
const List<OfficialSource> kOfficialSources = [
  OfficialSource(
    'src_yhq_title',
    'src_yhq_sub',
    'https://lex.uz/docs/-5953883',
  ),
  OfficialSource(
    'src_law_title',
    'src_law_sub',
    'https://lex.uz/docs/-6764454',
  ),
  OfficialSource(
    'src_exam_title',
    'src_exam_sub',
    'https://lex.uz/uz/docs/-7791514',
  ),
  OfficialSource('src_iiv_title', 'src_iiv_sub', 'https://gov.uz/uz/iiv'),
  OfficialSource('src_mygov_title', 'src_mygov_sub', 'https://my.gov.uz'),
];

/// "Sources and notice": says plainly that AvtoSmart is not a government
/// service, and links the original documents.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  Future<void> _open(BuildContext context, String url, String lang) async {
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(url), duration: const Duration(seconds: 4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(title: Text(s('sources_title'))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s('sources_not_gov_title'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s('sources_not_gov'),
                  style: const TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            s('sources_intro'),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppTheme.textM(context),
            ),
          ),
          const SizedBox(height: 12),
          for (final src in kOfficialSources)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SourceTile(
                title: s(src.titleKey),
                sub: s(src.subKey),
                shown: src.shown,
                onTap: () => _open(context, src.url, lang),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            s('sources_footer'),
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppTheme.textM(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final String title;
  final String sub;
  final String shown;
  final VoidCallback onTap;
  const _SourceTile({
    required this.title,
    required this.sub,
    required this.shown,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.hairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppTheme.textM(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shown,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.blue600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppTheme.textM(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
