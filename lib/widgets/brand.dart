import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';

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

/// Asosiy — ko'k gradient, oq matn, yumshoq soya; ikkilamchi — oq fon, ko'k
/// chegara va ko'k matn. Burchak 12 dp (saytdagi rounded-lg bilan bir xil).
/// Balandlik — minimal: katta shrift (textScale 1.3) matnni kesmaydi.
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
    final accent = AppTheme.brandAccent(context);
    final foreground = primary ? Colors.white : accent;
    final radius = BorderRadius.circular(AppTheme.radiusMd);

    final content = ConstrainedBox(
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
              // Dense buttons sit two to a row: one word that does not fit is
              // shrunk, never broken as "Variantla / r".
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
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    final Widget button = primary
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.blueDark.withValues(alpha: dark ? 0.4 : 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: radius,
                ),
                child: InkWell(onTap: onPressed, child: content),
              ),
            ),
          )
        : Material(
            color: dark ? Colors.transparent : AppTheme.lightCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: accent, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(onTap: onPressed, child: content),
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

/// "20 Savollar · 25 Daqiqa · 90% O'tish bali" — saytdagi TestStartPage
/// kataklari bilan bir xil: qiymat katta, izoh ostida kichik.
class StatCells extends StatelessWidget {
  final List<(String value, String label)> cells;
  const StatCells({super.key, required this.cells});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.card(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: AppTheme.hairline(context)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        cells[i].$1,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: AppTheme.textP(context),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cells[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: AppTheme.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sozlamalar kartasi: bir nechta [SettingsRow], orasida ingichka chiziq.
/// Material — qatorlarning bosish to'lqini karta foni ostida qolib ketmaydi.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.hairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 62,
                color: AppTheme.hairline(context),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Sozlamalar qatori — hammasi bir shaklda: siyoh ikonka qutisi, nom, joriy
/// qiymat, o'ngda o'q yoki switch. Rang faqat xavfli amalda (qizil).
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final bool destructive;
  final VoidCallback? onTap;

  /// The icon's colour (its square takes a light tint of it).
  final Color? color;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.color,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.destructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final iconFg = destructive
        ? AppTheme.error
        : (color ?? AppTheme.brandAccent(context));
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconFg.withValues(alpha: dark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 20, color: iconFg),
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
                        color: destructive
                            ? AppTheme.error
                            : AppTheme.textP(context),
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
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppTheme.mutedText(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Switch in the brand colours (ink track, white thumb) — as on the site.
class BrandSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const BrandSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppTheme.brandFill(context),
      // Off: a light outline and a muted thumb, not a heavy black knob.
      inactiveThumbColor: AppTheme.mutedText(context),
      inactiveTrackColor: AppTheme.isDark(context)
          ? Colors.white.withValues(alpha: 0.06)
          : AppTheme.lightScaffoldBg,
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : AppTheme.mutedText(context).withValues(alpha: 0.45),
      ),
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

  /// The icon's colour (its square takes a light tint of it).
  final Color? color;

  const SectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.subtitle,
    this.corner,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final radius = BorderRadius.circular(AppTheme.radiusMd);
    final tint = color ?? AppTheme.brandAccent(context);
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
                    color: tint.withValues(alpha: dark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(icon, size: 22, color: tint),
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

/// Bosh ekran sarlavhasi — ilovadagi boshqa sahifalar bilan bir xil yorug'
/// fonda (sayt kabi qora chiziq emas): chapda logotip, o'ngda til va PRO
/// "tabletkalari". Status bar ikonkalari fonga mos.
class BrandHeader extends StatelessWidget {
  final VoidCallback? onPro;
  final String proLabel;

  /// Shown before the PRO chip (e.g. [LanguageMenu]).
  final List<Widget> actions;

  const BrandHeader({
    super.key,
    this.onPro,
    this.proLabel = 'PRO',
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, top, 12, 0),
        color: dark ? AppTheme.scaffoldBg : AppTheme.lightScaffoldBg,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // The logo gives way first on a narrow phone or a wide font, so
              // the language and PRO pills never overflow.
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppHeaderLogo(height: 30),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ...actions,
              if (actions.isNotEmpty && onPro != null) const SizedBox(width: 8),
              if (onPro != null) _ProPill(label: proLabel, onTap: onPro!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oltin "PRO" tabletkasi — header'dagi yagona rangli dog'.
class _ProPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ProPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF78350F);
    final radius = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: radius,
          ),
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CrownIcon(size: 16, color: brown),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: brown,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "UZ ▾" — the site header's language switch, as a pill.
class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  static const Map<String, String> _short = {
    'uz_lat': 'UZ',
    'uz_cyr': 'ЎЗ',
    'ru': 'RU',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();
    return PopupMenuButton<String>(
      tooltip: provider.langLabel,
      initialValue: provider.lang,
      onSelected: provider.setLanguage,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      itemBuilder: (_) => [
        for (final l in LanguageProvider.languages)
          PopupMenuItem<String>(
            value: l['code'],
            height: 48,
            child: Row(
              children: [
                Expanded(child: Text(l['label']!)),
                if (l['code'] == provider.lang)
                  Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: AppTheme.brandAccent(context),
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 40, minWidth: 44),
        padding: const EdgeInsets.only(left: 12, right: 8),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.hairline(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _short[provider.lang] ?? 'UZ',
              style: TextStyle(
                color: AppTheme.textP(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppTheme.mutedText(context),
            ),
          ],
        ),
      ),
    );
  }
}
