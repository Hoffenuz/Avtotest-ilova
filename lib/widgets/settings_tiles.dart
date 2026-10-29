import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'media_controls.dart';

/// Tezkor sozlama kafeli — 2 ustunli to'rda, bitta bosish bilan yoqiladi /
/// o'chiriladi. Yoqiq holat rang bilan ko'rinadi (fon, chegara, ikonka),
/// o'chiq holat — oddiy karta. Uzun ro'yxatdagi switch qatorlaridan ko'ra
/// tezroq topiladi va bosiladi.
class QuickToggleTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String onLabel;
  final String offLabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool proBadge;

  const QuickToggleTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.onLabel,
    required this.offLabel,
    required this.value,
    required this.onChanged,
    this.proBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final radius = BorderRadius.circular(AppTheme.radiusLg);
    final tint = dark ? Color.lerp(color, Colors.white, 0.25)! : color;

    return Semantics(
      toggled: value,
      label: title,
      child: Material(
        color: value
            ? color.withValues(alpha: dark ? 0.2 : 0.09)
            : AppTheme.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: value
                ? color.withValues(alpha: dark ? 0.55 : 0.4)
                : AppTheme.hairline(context),
            width: value ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: value ? color : AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 19,
                        color: value ? Colors.white : AppTheme.textM(context),
                      ),
                    ),
                    const Spacer(),
                    _MiniSwitch(value: value, color: tint),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textP(context),
                        ),
                      ),
                    ),
                    if (proBadge) ...[
                      const SizedBox(width: 5),
                      const ProBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  value ? onLabel : offLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: value ? tint : AppTheme.textM(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kichik switch ko'rinishi — holat kafelning o'zida; bosish butun kafelga.
class _MiniSwitch extends StatelessWidget {
  final bool value;
  final Color color;
  const _MiniSwitch({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value
              ? color
              : AppTheme.textM(context).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kafellar 2 ustunda, bir qatordagilar bir xil balandlikda.
class QuickToggleGrid extends StatelessWidget {
  final List<Widget> tiles;
  const QuickToggleGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < tiles.length
                      ? tiles[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
