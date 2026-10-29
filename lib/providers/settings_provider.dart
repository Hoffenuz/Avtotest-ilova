import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The choices a user makes about how studying behaves.
///
/// One provider rather than one per setting: they are read together, saved
/// together, and shown together on one screen, and splitting them was how the
/// settings screen ended up with three different-looking controls for three
/// settings that are the same kind of thing.
class SettingsProvider extends ChangeNotifier {
  static const _scaleKey = 'question_text_scale';
  static const _autoExplanationKey = 'auto_explanation_on_wrong';
  static const _autoAdvanceKey = 'auto_advance_next_question';
  static const _animationsKey = 'question_animations';

  // ── Question text size ────────────────────────────────────────────────
  //
  // 0.9 is a small but real reduction; 1.4 is about as large as four answers
  // can get and still leave a question visible on a short screen.
  static const double minScale = 0.9;
  static const double maxScale = 1.4;
  static const double defaultScale = 1.0;

  /// Steps the slider snaps to, so the value is always one of a few sane
  /// sizes rather than 1.0733.
  static const int scaleDivisions = 5;

  double _scale = defaultScale;
  double get scale => _scale;
  String get scaleLabel => '${(_scale * 100).round()}%';
  bool get isDefaultScale => (_scale - defaultScale).abs() < 0.001;

  // ── Explanation after a wrong answer ──────────────────────────────────

  /// OFF by default.
  ///
  /// A sheet that opens by itself on every mistake interrupts the run: during
  /// a 100-question test it is a hundred interruptions, and someone drilling
  /// at speed wants to keep going and read the explanations afterwards. It
  /// stays available for people who do want to be stopped and taught at the
  /// moment they got it wrong — but they have to ask for it.
  bool _autoExplanation = false;
  bool get autoExplanation => _autoExplanation;

  // ── Moving on to the next question by itself ──────────────────────────

  /// OFF by default, and remembered.
  ///
  /// Jumping away 1.2 s after a tap takes the question off the screen before
  /// someone has read why their answer was wrong, and it used to switch
  /// itself back on at the start of every test. People who want the pace ask
  /// for it once — in Settings or on the test toolbar — and it stays.
  bool _autoAdvance = false;
  bool get autoAdvance => _autoAdvance;

  // ── Savol animatsiyalari ──────────────────────────────────────────────

  /// Standart holatda YOQIQ.
  ///
  /// Javobdan keyin vaziyat videosi rasm o'rnida o'zi o'ynaydi (saytdagi
  /// `useTestSettings.animations` bilan bir xil). O'chirilsa video umuman
  /// yuklanmaydi — rasm qoladi. Bepul foydalanuvchida ham sozlama ko'rinadi
  /// va o'zgartiriladi (namuna videolari shu sozlamaga bo'ysunadi).
  bool _animations = true;
  bool get animations => _animations;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedScale = prefs.getDouble(_scaleKey);
      if (savedScale != null) _scale = savedScale.clamp(minScale, maxScale);
      _autoExplanation = prefs.getBool(_autoExplanationKey) ?? false;
      _autoAdvance = prefs.getBool(_autoAdvanceKey) ?? false;
      _animations = prefs.getBool(_animationsKey) ?? true;
    } catch (e) {
      debugPrint('SettingsProvider.init: $e');
    }
    notifyListeners();
  }

  Future<void> setScale(double value) async {
    final next = value.clamp(minScale, maxScale);
    if ((next - _scale).abs() < 0.001) return;
    _scale = next;
    notifyListeners();
    await _write((prefs) => prefs.setDouble(_scaleKey, next));
  }

  Future<void> resetScale() => setScale(defaultScale);

  Future<void> setAutoExplanation(bool value) async {
    if (value == _autoExplanation) return;
    _autoExplanation = value;
    notifyListeners();
    await _write((prefs) => prefs.setBool(_autoExplanationKey, value));
  }

  Future<void> setAutoAdvance(bool value) async {
    if (value == _autoAdvance) return;
    _autoAdvance = value;
    notifyListeners();
    await _write((prefs) => prefs.setBool(_autoAdvanceKey, value));
  }

  Future<void> setAnimations(bool value) async {
    if (value == _animations) return;
    _animations = value;
    notifyListeners();
    await _write((prefs) => prefs.setBool(_animationsKey, value));
  }

  /// The UI has already been updated by the time this runs; a failed write
  /// costs the setting on the next launch, not the current session.
  Future<void> _write(Future<void> Function(SharedPreferences) action) async {
    try {
      await action(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('SettingsProvider write failed: $e');
    }
  }
}
