import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Intrinsic `width / height` of every bundled question illustration.
///
/// WHY THIS EXISTS (docs/MOBILE-CONTENT-PROMPT.md §7.1): a question card that
/// does not know how tall its picture will be lays out with a zero-height box,
/// then grows when the image finishes decoding — pushing the answer buttons
/// down under a finger that was already reaching for one. On the website the
/// same defect measured CLS 0.68. Knowing the aspect ratio up front lets the
/// card reserve the exact box before the first byte is decoded.
///
/// The manifest is generated on the website (`scripts/generate-image-sizes.cjs`)
/// and copied in by `tools/gen_data.py`, so a newly added picture brings its
/// size along instead of falling back to a guess.
class QuestionImageSizes {
  QuestionImageSizes._();

  static const String assetPath = 'assets/tests-json/image-sizes.json';

  /// About 97% of the images are named `u<number>uz.webp`; the manifest keys
  /// those by the bare number and everything else by full file name.
  static final RegExp _numberedName = RegExp(r'^u(\d+)uz\.webp$');

  /// Median ratio of the 736 bundled images (1280 / 794 ≈ 1.61), used when a
  /// file is missing from the manifest. Reserving a slightly wrong box still
  /// beats reserving none: `BoxFit.contain` letterboxes inside it and nothing
  /// moves once the picture arrives.
  static const double fallbackAspectRatio = 1280 / 794;

  static Map<String, double>? _numbered;
  static Map<String, double>? _other;
  static Future<void>? _loading;

  /// True once [load] has finished; until then every lookup returns the
  /// fallback ratio.
  static bool get isLoaded => _numbered != null;

  /// Parses the manifest. Called once at start-up so the first question card
  /// already has real numbers; safe to call again (later calls are no-ops).
  static Future<void> load() {
    if (_numbered != null) return SynchronousFuture(null);
    return _loading ??= _parse().whenComplete(() => _loading = null);
  }

  static Future<void> _parse() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final map = json.decode(raw) as Map<String, dynamic>;
      _numbered = _ratios(map['numbered']);
      _other = _ratios(map['other']);
    } catch (e) {
      // A missing or malformed manifest must not stop the app from showing
      // questions — it only costs the reserved-space optimisation.
      debugPrint('QuestionImageSizes: $assetPath unavailable ($e)');
      _numbered = const {};
      _other = const {};
    }
  }

  static Map<String, double> _ratios(dynamic source) {
    if (source is! Map<String, dynamic>) return const {};
    final out = <String, double>{};
    source.forEach((key, value) {
      if (value is! List || value.length != 2) return;
      final w = (value[0] as num?)?.toDouble();
      final h = (value[1] as num?)?.toDouble();
      if (w == null || h == null || w <= 0 || h <= 0) return;
      out[key] = w / h;
    });
    return out;
  }

  /// Aspect ratio for a question's `media_url` (a bare file name such as
  /// `u63-11.webp`). Never throws and never returns zero, so it is safe to
  /// hand straight to an [AspectRatio] widget.
  static double aspectRatioFor(String? fileName) {
    final name = fileName?.trim() ?? '';
    if (name.isEmpty) return fallbackAspectRatio;

    final numbered = _numberedName.firstMatch(name);
    if (numbered != null) {
      final hit = _numbered?[numbered.group(1)];
      if (hit != null) return hit;
    }
    return _other?[name] ?? fallbackAspectRatio;
  }

  @visibleForTesting
  static void resetForTest() {
    _numbered = null;
    _other = null;
    _loading = null;
  }
}
