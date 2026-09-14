import 'package:flutter/material.dart';

import '../services/app_strings.dart';

/// Full-screen viewer for a question illustration.
///
/// Intersection questions turn on which car is where and which lane a line
/// belongs to — details a thumbnail on a 5-inch screen genuinely hides. The
/// website has had a lightbox for this since the beginning; the app had the
/// picture and no way to look closer at it.
///
/// Opens with [show]; pinch or double-tap to zoom, drag to pan, tap the
/// backdrop or press back to close.
class ImageLightbox extends StatefulWidget {
  final String assetPath;
  final String closeLabel;

  const ImageLightbox({
    super.key,
    required this.assetPath,
    required this.closeLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required String fileName,
    required String uiLang,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, _, _) => ImageLightbox(
          assetPath: 'assets/tests-json/images/$fileName',
          closeLabel: AppStrings.get('close', uiLang),
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  @override
  State<ImageLightbox> createState() => _ImageLightboxState();
}

class _ImageLightboxState extends State<ImageLightbox>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Animation<Matrix4>? _zoom;

  /// Where the last double-tap landed, so zooming in centres on what the user
  /// was actually looking at rather than the middle of the picture.
  TapDownDetails? _lastTap;

  @override
  void initState() {
    super.initState();
    _animation.addListener(() {
      final value = _zoom?.value;
      if (value != null) _controller.value = value;
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final isZoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    final Matrix4 target;
    if (isZoomed) {
      target = Matrix4.identity();
    } else {
      final position = _lastTap?.localPosition ?? Offset.zero;
      const scale = 2.5;
      target = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (scale - 1),
          -position.dy * (scale - 1),
          0,
          1,
        )
        ..scaleByDouble(scale, scale, scale, 1);
    }

    _zoom = Matrix4Tween(
      begin: _controller.value,
      end: target,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    _animation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tapping the empty space around the picture closes the viewer.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Center(
            child: GestureDetector(
              onDoubleTapDown: (details) => _lastTap = details,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 5,
                child: Image.asset(
                  widget.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, _, _) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: widget.closeLabel,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
