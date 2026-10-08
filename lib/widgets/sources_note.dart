import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../screens/sources_screen.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// One short line saying the app is not a government service, with the way to
/// the sources. Sits at the foot of the screens that carry rules or exam
/// information, so it is seen without opening any menu.
class SourcesNote extends StatelessWidget {
  const SourcesNote({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final muted = AppTheme.textM(context);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () =>
            Navigator.push(context, AppTheme.slideRoute(const SourcesScreen())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${AppStrings.get('sources_note', lang)} ',
                    children: [
                      TextSpan(
                        text: AppStrings.get('sources_link', lang),
                        style: const TextStyle(
                          color: AppTheme.blue600,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: 12, height: 1.4, color: muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
