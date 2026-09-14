import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/supabase_config.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// "Join our Telegram group" strip for the bottom of the home screen.
///
/// Telegram's own blue, not the app's, so it reads as a link to somewhere
/// else rather than another in-app action.
class TelegramGroupBanner extends StatelessWidget {
  const TelegramGroupBanner({super.key});

  static const _telegramBlue = Color(0xFF0088CC);

  Future<void> _open() async {
    try {
      await launchUrl(
        Uri.parse(SupabaseConfig.telegramGroupUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      /* No Telegram / browser — nothing useful to say. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return InkWell(
      onTap: _open,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _telegramBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: _telegramBlue.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _telegramBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.telegram_rounded,
                color: _telegramBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s('telegram_group_title'),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textP(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s('telegram_group_body'),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppTheme.textM(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _open,
              style: FilledButton.styleFrom(
                backgroundColor: _telegramBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                s('telegram_group_join'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
