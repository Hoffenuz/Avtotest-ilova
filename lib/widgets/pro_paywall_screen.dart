import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../screens/pro_screen.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import 'brand.dart';

/// PRO subscription paywall shown when a user cannot access premium sections.
class ProPaywallAction {
  final String label;
  final IconData icon;

  /// Filled gradient button when set, outlined button when null.
  final LinearGradient? gradient;

  /// Label and icon colour on a [gradient] button.
  final Color foreground;
  final VoidCallback onTap;

  const ProPaywallAction({
    required this.label,
    required this.icon,
    this.gradient,
    this.foreground = Colors.white,
    required this.onTap,
  });
}

class ProPaywallScreen extends StatelessWidget {
  final String title;
  final String? error;
  final VoidCallback onRetry;
  final ProPaywallAction? primaryAction;
  final ProPaywallAction? secondaryAction;

  /// "Statusni yangilash" — only means something to a signed-in user whose
  /// subscription may have just been paid; a guest has no status to refresh.
  final bool showRefresh;

  const ProPaywallScreen({
    super.key,
    required this.title,
    this.error,
    required this.onRetry,
    this.primaryAction,
    this.secondaryAction,
    this.showRefresh = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // The same gold crown as the PRO button in the header.
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const CrownIcon(size: 44, color: AppTheme.proText),
              ),
              const SizedBox(height: 20),
              Text(
                s('pro_section_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textP(context),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  s('pro_section_body').replaceAll('{feature}', title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedText(context),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // The same promises as the PRO page — nothing the app lacks.
              _PerkRow(text: s('pro_perk_1')),
              _PerkRow(text: s('pro_perk_2')),
              _PerkRow(text: s('pro_perk_3')),
              _PerkRow(text: s('pro_perk_5')),
              const SizedBox(height: 24),
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 18,
                        color: AppTheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.get(error!, lang),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                      TextButton(onPressed: onRetry, child: Text(s('retry'))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (primaryAction != null) ...[
                _ActionButton(action: primaryAction!),
                const SizedBox(height: 12),
              ],
              if (secondaryAction != null) ...[
                _ActionButton(action: secondaryAction!),
                const SizedBox(height: 12),
              ],
              _ActionButton(
                action: ProPaywallAction(
                  label: s('subscribe_pro'),
                  icon: Icons.workspace_premium_rounded,
                  gradient: AppTheme.goldGradient,
                  foreground: AppTheme.proText,
                  onTap: () => _openProTab(context),
                ),
              ),
              if (showRefresh) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(s('refresh_status')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openProTab(BuildContext context) {
    Navigator.push(context, AppTheme.slideRoute(const ProScreen()));
  }
}

class _ActionButton extends StatelessWidget {
  final ProPaywallAction action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final gradient = action.gradient;

    // No gradient → secondary, outlined treatment.
    if (gradient == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: action.onTap,
          icon: Icon(action.icon, size: 18),
          label: Text(
            action.label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            side: BorderSide(color: AppTheme.hairline(context)),
            foregroundColor: AppTheme.textP(context),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            onTap: action.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: action.foreground),
                  const SizedBox(width: 8),
                  Text(
                    action.label,
                    style: TextStyle(
                      color: action.foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PerkRow extends StatelessWidget {
  final String text;
  const _PerkRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, color: AppTheme.textS(context)),
            ),
          ),
        ],
      ),
    );
  }
}
