import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../services/app_strings.dart';
import 'media_controls.dart';

/// Kattalashtirilgan savol videosi: butun ekran, qora fon, landscape'da ham
/// to'g'ri. ✕ yoki «orqaga» bilan yopiladi.
///
/// Ramkadagi controller'ning O'ZI beriladi (yangi yuklash yo'q, bir vaqtda
/// faqat bitta VideoPlayerController) — vaqt saqlanib qoladi: ramkada 5-soniyada
/// kattalashtirilsa shu yerda 5-soniyadan davom etadi, yopilganda ramka
/// controller holatidan (tugadi / pauza / o'ynayapti) davom etadi.
class VideoZoomScreen extends StatefulWidget {
  final VideoPlayerController controller;
  final String uiLang;

  const VideoZoomScreen({
    super.key,
    required this.controller,
    required this.uiLang,
  });

  static Future<void> show(
    BuildContext context, {
    required VideoPlayerController controller,
    required String uiLang,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        pageBuilder: (_, _, _) =>
            VideoZoomScreen(controller: controller, uiLang: uiLang),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  @override
  State<VideoZoomScreen> createState() => _VideoZoomScreenState();
}

enum _ZoomState { playing, paused, ended }

class _VideoZoomScreenState extends State<VideoZoomScreen> {
  _ZoomState _state = _ZoomState.paused;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  VideoPlayerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    // Ilova portretga qulflangan (main.dart); faqat shu ekranda burish mumkin.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _c.addListener(_onChange);
    _onChange();
    // Ochilishi bilan davom etadi; tugagan bo'lsa — boshidan.
    if (_c.value.isCompleted) {
      _restart();
    } else if (_c.value.isInitialized) {
      _c.play();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _progress.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _onChange() {
    final v = _c.value;
    if (v.duration > Duration.zero) {
      _progress.value = v.position.inMilliseconds / v.duration.inMilliseconds;
    }
    final next = v.isCompleted
        ? _ZoomState.ended
        : (v.isPlaying || v.isBuffering)
        ? _ZoomState.playing
        : _ZoomState.paused;
    if (next != _state && mounted) setState(() => _state = next);
  }

  Future<void> _restart() async {
    await _c.seekTo(Duration.zero);
    await _c.play();
  }

  void _toggle() {
    if (_state == _ZoomState.ended) {
      _restart();
    } else if (_c.value.isPlaying) {
      _c.pause();
    } else {
      _c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, widget.uiLang);
    final ratio = _c.value.isInitialized ? _c.value.aspectRatio : 16 / 9;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            label: s('anim_label'),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: Center(
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: VideoPlayer(_c),
                ),
              ),
            ),
          ),
          if (_state != _ZoomState.playing)
            Center(
              child: MediaRoundButton(
                icon: _state == _ZoomState.ended
                    ? Icons.replay_rounded
                    : Icons.play_arrow_rounded,
                label: s(
                  _state == _ZoomState.ended ? 'anim_replay' : 'anim_play',
                ),
                onTap: _toggle,
                size: 56,
                iconSize: 30,
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: MediaRoundButton(
                  icon: Icons.close_rounded,
                  label: s('close'),
                  onTap: () => Navigator.of(context).maybePop(),
                  size: 40,
                  iconSize: 22,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom,
            child: MediaProgressLine(progress: _progress, height: 3),
          ),
        ],
      ),
    );
  }
}
