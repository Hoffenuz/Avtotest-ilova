import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_version.dart';
import '../config/supabase_config.dart';
import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../services/app_update_service.dart';
import '../services/review_prompt_service.dart';
import '../theme/app_theme.dart';

/// "A new version is available — install it" strip.
///
/// Renders nothing at all until Play has actually said there is an update, so
/// it costs one collapsed widget on every other run.
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    // Fire and forget: the notifier rebuilds this widget if the answer is yes.
    AppUpdateService.check();
  }

  Future<void> _install() async {
    setState(() => _starting = true);
    await AppUpdateService.start();
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return ValueListenableBuilder<UpdateStatus>(
      valueListenable: AppUpdateService.statusListenable,
      builder: (context, status, _) {
        if (status != UpdateStatus.available &&
            status != UpdateStatus.readyToInstall) {
          return const SizedBox.shrink();
        }

        final ready = status == UpdateStatus.readyToInstall;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.blue.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppTheme.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s(
                        ready ? 'update_ready_title' : 'update_available_title',
                      ),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textP(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s(ready ? 'update_ready_body' : 'update_available_body'),
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
              if (_starting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.blue,
                  ),
                )
              else
                FilledButton(
                  onPressed: _install,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    s('update_action'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Version, a manual "check for updates", and the website link.
class AboutGroup extends StatefulWidget {
  const AboutGroup({super.key});

  @override
  State<AboutGroup> createState() => _AboutGroupState();
}

class _AboutGroupState extends State<AboutGroup> {
  bool _checking = false;

  Future<void> _checkNow(String lang) async {
    setState(() => _checking = true);
    final status = await AppUpdateService.check();
    if (!mounted) return;
    setState(() => _checking = false);

    // Only the "nothing to do" answer needs saying out loud — an available
    // update makes the banner appear, which says it better.
    if (status == UpdateStatus.upToDate || status == UpdateStatus.unknown) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('update_up_to_date', lang)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openSite() async {
    try {
      await launchUrl(
        Uri.parse(SupabaseConfig.siteUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      /* No browser — nothing useful to say. */
    }
  }

  Future<void> _openTelegramGroup() async {
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

    return Container(
      decoration: AppTheme.cardDeco(context),
      clipBehavior: Clip.antiAlias,
      // The card's own background is painted by the DecoratedBox above, which
      // would otherwise sit between these ListTiles and the nearest Material
      // and swallow their tap ripples.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: AppTheme.blue,
              ),
              title: Text(s('pro_version')),
              subtitle: Text(AppVersion.displayVersion),
              dense: true,
            ),
            Divider(height: 1, thickness: 1, color: AppTheme.border(context)),
            ListTile(
              leading: const Icon(
                Icons.system_update_rounded,
                color: AppTheme.blue,
              ),
              title: Text(s('check_for_updates')),
              trailing: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.blue,
                      ),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: _checking ? null : () => _checkNow(lang),
              dense: true,
            ),
            Divider(height: 1, thickness: 1, color: AppTheme.border(context)),
            // The people who open settings are the ones who use the app; they
            // are also the only ones who will ever rate it unprompted.
            ListTile(
              leading: const Icon(
                Icons.star_rounded,
                color: AppTheme.orange,
              ),
              title: Text(s('rate_app')),
              subtitle: Text(s('rate_app_sub')),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: ReviewPromptService.openStoreListing,
              dense: true,
            ),
            Divider(height: 1, thickness: 1, color: AppTheme.border(context)),
            ListTile(
              leading: const Icon(
                Icons.public_rounded,
                color: AppTheme.success,
              ),
              title: Text(s('visit_website')),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: _openSite,
              dense: true,
            ),
            Divider(height: 1, thickness: 1, color: AppTheme.border(context)),
            ListTile(
              leading: const Icon(
                Icons.telegram_rounded,
                color: Color(0xFF0088CC),
              ),
              title: Text(s('telegram_group_title')),
              subtitle: Text(s('telegram_group_body')),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: _openTelegramGroup,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
