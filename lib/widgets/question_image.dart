import 'package:flutter/material.dart';

import '../services/question_image_sizes.dart';
import '../theme/app_theme.dart';

/// A question's illustration, in a box whose height is known **before** the
/// picture decodes.
///
/// The old inline `Image.asset(width: double.infinity, fit: contain)` had no
/// height until the bytes arrived, so the answer buttons underneath jumped
/// down the moment they did — the mobile twin of the website's CLS 0.68 bug
/// (docs/MOBILE-CONTENT-PROMPT.md §7.1). [QuestionImageSizes] supplies the
/// intrinsic aspect ratio, [AspectRatio] reserves the box, and the image
/// letterboxes inside it.
class QuestionImage extends StatelessWidget {
  /// Bare file name from the question's `media_url`, e.g. `u63-11.webp`.
  final String fileName;

  /// Ceiling on the reserved height, so a portrait image cannot push the
  /// answers off screen. Matches the website's `max-h-52` on mobile.
  static const double defaultMaxHeight = 208;
  final double maxHeight;

  /// Frame colours. They default to the app theme, but the Real Exam passes
  /// fixed ones: that screen has to render identically in light and dark, and
  /// a theme-coloured frame around the picture was the one thing on it that
  /// still changed.
  final Color? backgroundColor;
  final Color? borderColor;

  final VoidCallback? onTap;

  /// Spoken instead of the picture when [onTap] is set.
  final String zoomLabel;

  const QuestionImage({
    super.key,
    required this.fileName,
    this.maxHeight = defaultMaxHeight,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.zoomLabel = '',
  });

  /// Physical pixels this picture is decoded into.
  ///
  /// Used to be the full screen width, which is right only for a wide image.
  /// A tall one is clamped by [maxHeight] to a much narrower box — a square
  /// image on a 360 dp phone draws about 208 dp across, so decoding it at
  /// 1080 px wasted roughly five times the memory it needed. Taking the
  /// smaller of the two bounds decodes each picture at the size it is drawn.
  ///
  /// STATIC AND PUBLIC ON PURPOSE. The test screen pre-warms the neighbouring
  /// questions' images, and a pre-warm only helps if it decodes at exactly
  /// the width the card will ask for — a different width is a different cache
  /// entry, so the work would be done twice and thrown away once.
  static int decodeWidthFor(
    BuildContext context,
    String fileName, {
    double maxHeight = defaultMaxHeight,
  }) {
    final ratio = QuestionImageSizes.aspectRatioFor(fileName);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ratioBoundWidth = maxHeight * ratio;
    final logical = screenWidth < ratioBoundWidth
        ? screenWidth
        : ratioBoundWidth;
    return (logical * MediaQuery.devicePixelRatioOf(context)).round();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = QuestionImageSizes.aspectRatioFor(fileName);
    final radius = BorderRadius.circular(AppTheme.radiusLg);

    final framed = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surface(context),
        border: Border.all(color: borderColor ?? AppTheme.border(context)),
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: ratio,
        child: Image.asset(
          'assets/tests-json/images/$fileName',
          fit: BoxFit.contain,
          // Decode at display resolution instead of full size — with ~736
          // question images this is a large chunk of the memory the app used
          // to hold while swiping through a test.
          cacheWidth: decodeWidthFor(context, fileName, maxHeight: maxHeight),
          // The frame keeps its reserved size on a decode failure rather than
          // collapsing and shifting everything below it.
          errorBuilder: (context, _, _) => Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 28,
              color: borderColor ?? AppTheme.textM(context),
            ),
          ),
        ),
      ),
    );

    // Centred: with a tall picture the ratio-driven box is narrower than the
    // column, and a left-aligned frame would look like a layout mistake.
    final sized = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: framed,
      ),
    );

    if (onTap == null) return ExcludeSemantics(child: sized);

    return Semantics(
      button: true,
      label: zoomLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ExcludeSemantics(
            child: Stack(
              children: [
                sized,
                // Without this nothing suggests the picture can be opened
                // larger, and on a small screen that is exactly the thing
                // people need and never discover.
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.zoom_out_map_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
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
