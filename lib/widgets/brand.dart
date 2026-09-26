import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import 'app_logo.dart';

/// Saytdagi (avtotestu.uz) dizayn bloklarining ilovadagi nusxasi — sayt va
/// ilova bitta mahsulotdek ko'rinishi uchun. Har biri sayt komponentiga mos:
/// [BrandButton] ↔ MainTestButtons, [SectionTile] ↔ SectionGrid,
/// [ProUpsellCard] ↔ ProUpsell, [BrandHeader] ↔ MainLayout header.

/// lucide "crown" — saytdagi toj bilan aynan bir xil shakl (Material'da yo'q).
const String _crownSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
    'stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
    '<path d="M11.562 3.266a.5.5 0 0 1 .876 0L15.39 8.87a1 1 0 0 0 1.516.294'
    'L21.183 5.5a.5.5 0 0 1 .798.519l-2.834 10.246a1 1 0 0 1-.956.734H5.81'
    'a1 1 0 0 1-.957-.734L2.02 6.02a.5.5 0 0 1 .798-.519l4.276 3.664'
    'a1 1 0 0 0 1.516-.294z"/><path d="M5 21h14"/></svg>';

class CrownIcon extends StatelessWidget {
  final double size;
  final Color color;
  const CrownIcon({super.key, this.size = 16, required this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _crownSvg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// "PRO" belgisi — bo'lim PRO talab qilishini bildiradi. Yumshoq oltin.
class ProTag extends StatelessWidget {
  const ProTag({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final text = dark ? AppTheme.proTextDark : AppTheme.proText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? AppTheme.proBgDark : AppTheme.proBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.proBorder.withValues(alpha: dark ? 0.3 : 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CrownIcon(size: 11, color: text),
          const SizedBox(width: 3),
          Text(
            'PRO',
            style: TextStyle(
              color: text,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

enum BrandButtonKind { primary, secondary }

/// Asosiy — to'la siyoh (qorong'ida indigo), ikkilamchi — fon + 2 dp siyoh
/// chegara. Burchak 8 dp. Balandlik — minimal: katta shrift (textScale 1.3)
/// matnni kesmaydi, tugma o'sadi.
class BrandButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final BrandButtonKind kind;
  final double minHeight;
  final bool proTag;

  /// Half-width buttons side by side: smaller text and padding.
  final bool dense;

  const BrandButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.kind = BrandButtonKind.primary,
    this.minHeight = 52,
    this.proTag = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final primary = kind == BrandButtonKind.primary;
    final fill = AppTheme.brandFill(context);
    final foreground = primary || dark ? Colors.white : AppTheme.ink;
    final radius = BorderRadius.circular(AppTheme.radiusSm);

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: primary
            ? [
                BoxShadow(
                  color: fill.withValues(alpha: dark ? 0.35 : 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: primary
            ? fill
            : (dark ? Colors.transparent : AppTheme.lightCardBg),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: primary
              ? BorderSide.none
              : BorderSide(color: dark ? AppTheme.indigo : AppTheme.ink, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 10 : 20,
                vertical: dense ? 8 : 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: IconThemeData(color: foreground, size: dense ? 20 : 22),
                    child: icon,
                  ),
                  SizedBox(width: dense ? 8 : 10),
                  Flexible(
                    // Dense buttons sit two to a row: one word that does not
                    // fit is shrunk, never broken as "Variantla / r".
                    child: dense
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!proTag) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        const Positioned(right: -6, top: -8, child: ProTag()),
      ],
    );
  }
}

/// Bo'lim plitkasi: siyoh ikonka qutisi, nom (kesilmaydi, o'raladi),
/// o'q; PRO / qulf / son — burchakda, nomdan joy olmaydi.
class SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? corner;

  const SectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.corner,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final radius = BorderRadius.circular(AppTheme.radiusMd);
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: AppTheme.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AppTheme.hairline(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.ink.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: dark ? Colors.white : AppTheme.ink,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: AppTheme.textP(context),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: AppTheme.mutedText(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppTheme.mutedText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (corner == null) return tile;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tile,
        Positioned(right: -6, top: -8, child: corner!),
      ],
    );
  }
}

/// PRO taklifi — tinch oq karta: och oltin toj, siyoh matn, o'ngda
/// "Pro olish →". Ko'rinadi, lekin asosiy harakatdan e'tiborni tortmaydi.
class ProUpsellCard extends StatelessWidget {
  final String title;
  final String description;
  final String action;
  final VoidCallback onTap;

  const ProUpsellCard({
    super.key,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final radius = BorderRadius.circular(AppTheme.radiusLg);
    return Material(
      color: AppTheme.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppTheme.hairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dark
                      ? AppTheme.proBorder.withValues(alpha: 0.1)
                      : AppTheme.proBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                alignment: Alignment.center,
                child: CrownIcon(
                  size: 20,
                  color: dark ? AppTheme.proBorder : AppTheme.proIcon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textP(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppTheme.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandAccent(context),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppTheme.brandAccent(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Siyoh header — saytning tanish belgisi. Ikkala temada ham siyoh, shuning
/// uchun status bar ikonkalari doim oq.
class BrandHeader extends StatelessWidget {
  final VoidCallback? onPro;
  final String proLabel;

  const BrandHeader({super.key, this.onPro, this.proLabel = 'PRO'});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, top, 12, 0),
        decoration: BoxDecoration(
          color: dark ? AppTheme.inkHeaderDark : AppTheme.ink,
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const AppHeaderLogo(height: 30, onBrand: true),
              const Spacer(),
              if (onPro != null)
                Material(
                  color: AppTheme.proBorder.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    side: BorderSide(
                      color: AppTheme.proBorder.withValues(alpha: 0.4),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPro,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CrownIcon(size: 16, color: AppTheme.proBorder),
                          const SizedBox(width: 6),
                          Text(
                            proLabel,
                            style: const TextStyle(
                              color: Color(0xFFFEF3C7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
