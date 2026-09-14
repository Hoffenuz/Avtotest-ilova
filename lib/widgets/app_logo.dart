import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Brand logo asset used across the app.
class AppLogo extends StatelessWidget {
  final double height;
  final BoxFit fit;
  final bool circular;

  const AppLogo({
    super.key,
    this.height = 48,
    this.fit = BoxFit.cover,
    this.circular = false,
  });

  static const assetPath = 'assets/logo.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      height: height,
      width: circular ? height : null,
      fit: fit,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.directions_car_rounded,
        size: height * 0.65,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (!circular) return image;

    return ClipOval(
      child: SizedBox(height: height, width: height, child: image),
    );
  }
}

/// Full header lockup — icon + "AvtoSmart" wordmark, no tagline — as the
/// real brand SVG rather than an icon widget next to a Text.
///
/// The brand kit only ships this combination as a *white* asset (for dark
/// grounds) or a *colored* one (for light grounds); there's no single file
/// that reads on both. So this picks between the two real vector files by
/// theme instead of forcing one onto a background it wasn't drawn for.
class AppHeaderLogo extends StatelessWidget {
  final double height;

  const AppHeaderLogo({super.key, this.height = 28});

  static const _light = 'assets/branding/logo_notag.svg';
  static const _dark = 'assets/branding/logo_white_notag.svg';

  @override
  Widget build(BuildContext context) {
    final asset = AppTheme.isDark(context) ? _dark : _light;
    return SvgPicture.asset(asset, height: height, alignment: Alignment.centerLeft);
  }
}
