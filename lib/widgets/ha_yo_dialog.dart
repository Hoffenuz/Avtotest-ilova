import 'package:flutter/material.dart';

import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// Confirmation dialog with prominent Ha / Yo'q action buttons.
Future<bool?> showHaYoDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String lang,
  String? yesLabel,
  String? noLabel,
  bool destructive = false,
}) {
  final yes = yesLabel ?? AppStrings.get('yes', lang);
  final no = noLabel ?? AppStrings.get('no', lang);

  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              destructive ? Icons.logout_rounded : Icons.help_outline_rounded,
              size: 44,
              color: destructive ? AppTheme.error : AppTheme.blue,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textP(ctx),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppTheme.textM(ctx),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _HaYoButton(
                    label: no,
                    color: AppTheme.textM(ctx),
                    background: AppTheme.surface(ctx),
                    borderColor: AppTheme.border(ctx),
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HaYoButton(
                    label: yes,
                    color: Colors.white,
                    background: destructive ? AppTheme.error : AppTheme.blue,
                    borderColor: destructive ? AppTheme.error : AppTheme.blue,
                    onTap: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _HaYoButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  const _HaYoButton({
    required this.label,
    required this.color,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
