import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/anim_demo.dart';
import '../services/animation_index_service.dart';
import '../services/app_strings.dart';
import '../services/data_saver_service.dart';
import 'image_lightbox.dart';
import 'media_controls.dart';
import 'question_image.dart';
import 'video_zoom_screen.dart';

/// Savol rasmi + (bor bo'lsa) animatsiya, BITTA ramkada — saytdagi
/// `QuestionMedia.tsx` bilan bir xil xatti-harakat.
///
/// Rasm o'lchamni belgilaydi ([QuestionImage], `question_image_sizes.dart`),
/// video rasm ustiga qatlam sifatida chiqadi — almashganda maket siljimaydi,
/// birinchi kadr kelguncha rasm ko'rinib turadi.
///
/// Animatsiya to'g'ri harakatni KO'RSATADI (javobni oshkor qiladi), shuning
/// uchun faqat javobdan keyin ([revealed]) o'ynaydi. Javobdan oldin hech
/// qanday yorliq yoki tugma yo'q.
///
/// Xato (404, kodek, tarmoq) — rasm qoladi, xabar chiqmaydi, avto-o'tish
/// davom etadi ([onAnimationDone] baribir chaqiriladi).
class QuestionMedia extends StatelessWidget {
  /// Savolning `media_url` (fayl nomi, masalan `u1003uz.webp`).
  final String fileName;
  final String uiLang;

  /// Savolga javob berilganmi.
  final bool revealed;
  final bool isPremium;

  /// ⚙ → Animatsiyalar sozlamasi. O'chiq bo'lsa video umuman yuklanmaydi.
  final bool animationsEnabled;

  /// Shu sahifa hozir ekranda (PageView joriy indeksi). Faqat faol savolda
  /// controller yaratiladi — bir vaqtda bitta VideoPlayerController.
  final bool active;

  /// Izoh oynasi ochiq va h.k. — video pauza, avto-boshlanish kutadi.
  final bool suspended;

  /// Video tugadi / o'ynab bo'lmadi — avto-o'tish shundan keyin davom etadi.
  /// Har javob uchun bir marta.
  final VoidCallback? onAnimationDone;

  /// «▶ PRO» / «Namuna n/2 · PRO» bosilganda — PRO ekrani.
  final VoidCallback? onOpenPro;

  final double maxHeight;

  const QuestionMedia({
    super.key,
    required this.fileName,
    required this.uiLang,
    required this.revealed,
    required this.isPremium,
    this.animationsEnabled = true,
    this.active = true,
    this.suspended = false,
    this.onAnimationDone,
    this.onOpenPro,
    this.maxHeight = QuestionImage.defaultMaxHeight,
  });

  /// Javobdan keyin shu savolda video o'ynaydimi — avto-o'tish shunga qarab
  /// video tugashini kutadi (`AutoAdvanceScheduler`).
  static bool willPlay({
    required String? fileName,
    required bool isPremium,
    required bool animationsEnabled,
  }) {
    if (!animationsEnabled) return false;
    if (AnimationIndexService.urlFor(fileName) == null) return false;
    return isPremium ||
        AnimDemo.allowed(AnimationIndexService.keyFor(fileName));
  }

  @override
  Widget build(BuildContext context) {
    final url = animationsEnabled
        ? AnimationIndexService.urlFor(fileName)
        : null;
    if (url == null) return _image(context);

    // Bepul: birinchi 2 ta animatsiyali savol — namuna (PRO'dagidek o'ynaydi)
    final demo =
        !isPremium && AnimDemo.allowed(AnimationIndexService.keyFor(fileName));

    if (!isPremium && !demo) {
      // Namuna tugagan: video yuklanmaydi; javobdan keyin burchakda ▶ PRO
      return _image(
        context,
        showZoomHint: !revealed,
        overlay: revealed
            ? Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _ProChip(
                    label: '${AppStrings.get('anim_label', uiLang)} — PRO',
                    onTap: onOpenPro,
                  ),
                ),
              )
            : null,
      );
    }

    return _AnimatedMedia(
      key: ValueKey(url),
      url: url,
      fileName: fileName,
      uiLang: uiLang,
      revealed: revealed,
      demo: demo,
      active: active,
      suspended: suspended,
      maxHeight: maxHeight,
      onAnimationDone: onAnimationDone,
      onOpenPro: onOpenPro,
    );
  }

  Widget _image(
    BuildContext context, {
    Widget? overlay,
    bool showZoomHint = true,
  }) {
    return QuestionImage(
      fileName: fileName,
      maxHeight: maxHeight,
      overlay: overlay,
      showZoomHint: showZoomHint,
      zoomLabel: AppStrings.get('zoom_image', uiLang),
      onTap: () =>
          ImageLightbox.show(context, fileName: fileName, uiLang: uiLang),
    );
  }
}

/// Javobdan keyin rasm shuncha vaqt qorayadi (yozuvsiz kichik loading),
/// keyin video chiqadi. Rasm bir lahzada videoga almashib qolsa kadr «o'zi
/// qimirlab ketgandek» g'alati ko'rinadi — qisqa qorayish almashinuvni
/// yozuvsiz bildiradi.
const Duration kAnimationIntro = Duration(milliseconds: 600);

/// Video shuncha vaqtda boshlanmasa avto-o'tish kutib qolmasin (sekin tarmoq).
const Duration kAnimationStartTimeout = Duration(seconds: 8);

enum _Phase { idle, intro, loading, playing, paused, ended, image, error }

class _AnimatedMedia extends StatefulWidget {
  final String url;
  final String fileName;
  final String uiLang;
  final bool revealed;
  final bool demo;
  final bool active;
  final bool suspended;
  final double maxHeight;
  final VoidCallback? onAnimationDone;
  final VoidCallback? onOpenPro;

  const _AnimatedMedia({
    super.key,
    required this.url,
    required this.fileName,
    required this.uiLang,
    required this.revealed,
    required this.demo,
    required this.active,
    required this.suspended,
    required this.maxHeight,
    required this.onAnimationDone,
    required this.onOpenPro,
  });

  @override
  State<_AnimatedMedia> createState() => _AnimatedMediaState();
}

class _AnimatedMediaState extends State<_AnimatedMedia>
    with WidgetsBindingObserver {
  _Phase _phase = _Phase.idle;
  VideoPlayerController? _controller;
  Future<void>? _init;
  Timer? _introTimer;
  Timer? _startTimer;
  bool _done = false;
  bool _pausedBySuspend = false;
  int _demoNo = 0;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  String get _animKey => AnimationIndexService.keyFor(widget.fileName) ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Allaqachon javob berilgan savolga qaytildi — rasm + burchakda ▶.
    // Qayta o'ynatish foydalanuvchining qo'lida (trafik tejaladi).
    if (widget.revealed) _phase = _Phase.image;
    if (widget.active) _preload();
  }

  @override
  void didUpdateWidget(covariant _AnimatedMedia old) {
    super.didUpdateWidget(old);
    if (!old.revealed && widget.revealed) _onRevealed();
    if (old.active && !widget.active) {
      _disposeController();
      _phase = widget.revealed ? _Phase.image : _Phase.idle;
    } else if (!old.active && widget.active) {
      _preload();
    }
    if (!old.suspended && widget.suspended) _suspend();
    if (old.suspended && !widget.suspended) _resume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _introTimer?.cancel();
    _startTimer?.cancel();
    _disposeController();
    _progress.dispose();
    super.dispose();
  }

  /// Ilova fonga o'tganda video to'xtaydi; qaytganda ▶ bilan davom etadi.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.inactive) {
      return;
    }
    if (_phase == _Phase.playing || _phase == _Phase.loading) {
      _controller?.pause();
      _startTimer?.cancel();
      if (mounted) setState(() => _phase = _Phase.paused);
    }
  }

  // ── Yuklash ──────────────────────────────────────────────────────────

  /// PRO (yoki namuna huquqi bor) foydalanuvchida savol ochilganda video
  /// javobdan OLDIN fon rejimida yuklanib tursin — javob bosilganda darhol
  /// boshlansin. Tejamkor rejimda (Data Saver) — faqat javobdan keyin.
  Future<void> _preload() async {
    if (_controller != null || widget.revealed) return;
    final saver = await DataSaverService.isEnabled();
    if (!mounted || saver || !widget.active || _controller != null) return;
    _ensureController();
  }

  VideoPlayerController _ensureController() {
    final existing = _controller;
    if (existing != null) return existing;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      // Ovozsiz video — foydalanuvchining musiqasini to'xtatmasin.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = c;
    c.addListener(_onControllerChanged);
    _init = c
        .initialize()
        .then((_) async {
          await c.setVolume(0);
          await c.setLooping(false);
        })
        .catchError((Object e) {
          if (_controller == c) _onError();
        });
    return c;
  }

  void _disposeController() {
    final c = _controller;
    if (c == null) return;
    _controller = null;
    _init = null;
    c.removeListener(_onControllerChanged);
    c.dispose();
  }

  // ── Holat mashinasi ──────────────────────────────────────────────────

  /// Javob berilishi bilan: qisqa qorayish, keyin o'zi o'ynaydi.
  void _onRevealed() {
    _done = false;
    _introTimer?.cancel();
    if (widget.suspended) {
      // Izoh oynasi ochiq — yopilgach boshlanadi (_resume).
      _phase = _Phase.idle;
      return;
    }
    setState(() => _phase = _Phase.intro);
    // Namuna javob berilganda sarflanadi (video haqiqatan ko'rsatiladi)
    if (widget.demo) _demoNo = AnimDemo.consume(_animKey);
    _introTimer = Timer(kAnimationIntro, _start);
  }

  Future<void> _start() async {
    if (!mounted) return;
    final c = _ensureController();
    setState(() => _phase = _Phase.loading);
    _progress.value = 0;
    _startTimer?.cancel();
    // Sekin tarmoq: video boshlanmasa ham avto-o'tish to'xtab qolmaydi
    _startTimer = Timer(kAnimationStartTimeout, () {
      if (_phase == _Phase.loading) _finish();
    });
    try {
      await _init;
      if (!mounted || _controller != c) return;
      if (c.value.hasError) {
        _onError();
        return;
      }
      await c.seekTo(Duration.zero);
      await c.play();
    } catch (_) {
      if (mounted && _controller == c) _onError();
    }
  }

  void _onControllerChanged() {
    final c = _controller;
    if (c == null || !mounted) return;
    final v = c.value;
    if (v.hasError) {
      _onError();
      return;
    }
    if (v.duration > Duration.zero) {
      _progress.value = v.position.inMilliseconds / v.duration.inMilliseconds;
    }
    if (_phase == _Phase.loading && v.isPlaying) {
      _startTimer?.cancel();
      setState(() => _phase = _Phase.playing);
    }
    if (v.isCompleted &&
        (_phase == _Phase.playing || _phase == _Phase.loading)) {
      _progress.value = 1;
      setState(() => _phase = _Phase.ended);
      _finish();
    }
  }

  /// Avto-o'tishga «davom et» signali — har javob uchun bir marta.
  void _finish() {
    if (_done) return;
    _done = true;
    _startTimer?.cancel();
    widget.onAnimationDone?.call();
  }

  /// Xato — rasm qoladi, xabar chiqmaydi, test to'xtamaydi.
  void _onError() {
    if (_phase == _Phase.error) return;
    _startTimer?.cancel();
    _disposeController();
    if (mounted) setState(() => _phase = _Phase.error);
    _finish();
  }

  void _suspend() {
    _introTimer?.cancel();
    if (_phase == _Phase.intro) {
      _phase = _Phase.idle;
      return;
    }
    if (_phase == _Phase.playing || _phase == _Phase.loading) {
      _controller?.pause();
      _startTimer?.cancel();
      _pausedBySuspend = true;
      setState(() => _phase = _Phase.paused);
    }
  }

  void _resume() {
    if (_phase == _Phase.idle && widget.revealed && !_done) {
      _onRevealed();
      return;
    }
    if (_pausedBySuspend && _phase == _Phase.paused) {
      _pausedBySuspend = false;
      _controller?.play();
      setState(() => _phase = _Phase.playing);
    }
  }

  // ── Foydalanuvchi boshqaruvi ─────────────────────────────────────────

  /// Videoga tegish: pauza / davom / tugagan bo'lsa qayta.
  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    switch (_phase) {
      case _Phase.ended:
        _start();
      case _Phase.playing:
        c.pause();
        setState(() => _phase = _Phase.paused);
      case _Phase.paused:
        _pausedBySuspend = false;
        c.play();
        setState(() => _phase = _Phase.playing);
      default:
        break;
    }
  }

  void _showImage() {
    _controller?.pause();
    _pausedBySuspend = false;
    setState(() => _phase = _Phase.image);
  }

  Future<void> _openZoom() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    await VideoZoomScreen.show(context, controller: c, uiLang: widget.uiLang);
    if (!mounted || _controller != c) return;
    final v = c.value;
    setState(() {
      _phase = v.isCompleted
          ? _Phase.ended
          : v.isPlaying
          ? _Phase.playing
          : _Phase.paused;
    });
    // Kattalashtirib ko'rib tugatdi — avto-o'tish endi (yopilgach) davom etadi
    if (v.isCompleted) _finish();
  }

  // ── Chizish ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, widget.uiLang);
    final c = _controller;
    final videoVisible =
        widget.revealed &&
        c != null &&
        c.value.isInitialized &&
        (_phase == _Phase.playing ||
            _phase == _Phase.paused ||
            _phase == _Phase.ended);
    final dimmed =
        widget.revealed && (_phase == _Phase.intro || _phase == _Phase.loading);
    final cornerButtons = videoVisible || _phase == _Phase.image;

    final overlay = Stack(
      fit: StackFit.expand,
      children: [
        if (videoVisible)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _togglePlay,
            onDoubleTap: _openZoom,
            child: Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: c.value.aspectRatio,
                  child: VideoPlayer(c),
                ),
              ),
            ),
          ),

        // Rasm → video almashinuvi: yozuvsiz qorayish va kichik loading
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: dimmed ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: dimmed
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // Bepul namuna: nechanchi ekani — PRO'da cheklov yo'qligini bildiradi
        if (widget.demo && _demoNo > 0 && videoVisible)
          Positioned(
            left: 8,
            top: 8,
            child: _ProChip(
              text: s('anim_demo')
                  .replaceAll('{n}', '$_demoNo')
                  .replaceAll('{total}', '${AnimDemo.limit}'),
              label: s('anim_demo')
                  .replaceAll('{n}', '$_demoNo')
                  .replaceAll('{total}', '${AnimDemo.limit}'),
              onTap: widget.onOpenPro,
            ),
          ),

        // Pauza yoki tugadi — markazda faqat ikonka
        if (videoVisible &&
            (_phase == _Phase.paused || _phase == _Phase.ended))
          Center(
            child: MediaRoundButton(
              icon: _phase == _Phase.ended
                  ? Icons.replay_rounded
                  : Icons.play_arrow_rounded,
              label: s(_phase == _Phase.ended ? 'anim_replay' : 'anim_play'),
              onTap: _togglePlay,
              size: 44,
              iconSize: 24,
            ),
          ),

        // Burchak: kattalashtirish + video ↔ rasm
        if (cornerButtons)
          Positioned(
            right: 8,
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (videoVisible) ...[
                  MediaRoundButton(
                    icon: Icons.open_in_full_rounded,
                    label: s('anim_fullscreen'),
                    onTap: _openZoom,
                    iconSize: 16,
                  ),
                  const SizedBox(width: 6),
                ],
                MediaRoundButton(
                  icon: videoVisible
                      ? Icons.image_outlined
                      : Icons.play_arrow_rounded,
                  label: s(videoVisible ? 'anim_show_image' : 'anim_label'),
                  onTap: videoVisible ? _showImage : _start,
                ),
              ],
            ),
          ),

        if (videoVisible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MediaProgressLine(progress: _progress),
          ),
      ],
    );

    return QuestionImage(
      fileName: widget.fileName,
      maxHeight: widget.maxHeight,
      overlay: overlay,
      // Video ko'rinib turganda rasmga bosish videoni boshqaradi, lightbox emas
      onTap: videoVisible
          ? null
          : () => ImageLightbox.show(
              context,
              fileName: widget.fileName,
              uiLang: widget.uiLang,
            ),
      showZoomHint: !cornerButtons && !dimmed,
      zoomLabel: s('zoom_image'),
    );
  }
}

/// Burchakdagi kichik qora pill: «▶ PRO» yoki «Namuna 1/2 PRO» → PRO ekrani.
class _ProChip extends StatelessWidget {
  final String? text;
  final String label;
  final VoidCallback? onTap;

  const _ProChip({this.text, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (text != null)
                  Text(
                    text!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                const SizedBox(width: 4),
                const ProBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
