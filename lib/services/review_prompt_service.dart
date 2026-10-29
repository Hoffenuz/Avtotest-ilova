import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_version.dart';

/// Asks Google Play to show its rating sheet, but only at a moment when the
/// user is likely to be pleased with the app.
///
/// WHY THIS EXISTS: Play ranks on rating count as much as on rating value, and
/// the store listing itself is judged by it — a row that says "6 reviews"
/// loses to one that says "424 reviews" before anybody reads a word. Installs
/// alone will not close that gap; the people who already passed a test have to
/// be asked.
///
/// WHY ONLY AFTER A PASSED TEST: the prompt inherits the mood of the screen it
/// appears on. Asking someone who has just failed converts a neutral user into
/// a one-star review, and a one-star review costs far more than the rating it
/// would have gained.
///
/// WHY THE COUNTERS: Play's own API silently swallows most requests — there is
/// a per-user quota and no way to read it — so it is impossible to know
/// whether a sheet was actually shown. The counters here are not a substitute
/// for that quota; they exist so this app does not burn its one allowed
/// showing on a user who installed twenty minutes ago and has no opinion yet.
///
/// Every call fails soft. A rating prompt is a nicety; it must never be the
/// reason a result screen misbehaves.
class ReviewPromptService {
  ReviewPromptService._();

  static const _finishedTestsKey = 'review_finished_tests';
  static const _lastPromptKey = 'review_last_prompt_ms';
  static const _promptCountKey = 'review_prompt_count';

  /// Completed tests before the first ask. Three is enough to mean the app is
  /// being used, and short enough to land inside the first week for an active
  /// user — which is when they are most willing.
  static const int minFinishedTests = 3;

  /// Nothing is asked again inside this window, even if every other condition
  /// is met.
  static const Duration promptInterval = Duration(days: 30);

  /// A user who has said nothing after three asks is not going to.
  static const int maxPrompts = 3;

  static final InAppReview _review = InAppReview.instance;

  /// One ask per app session at most, whatever the stored counters say.
  static bool _askedThisSession = false;

  /// Play's review API is Android-only here; the app ships nowhere else.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Call when a test finishes. Records the run and, if this is a good
  /// moment, asks Play to show the rating sheet.
  ///
  /// [percentage] is 0..1, matching `TestResult.percentage`.
  static Future<void> onTestFinished({
    required double percentage,
    required bool isPassed,
    required bool isCompleted,
  }) async {
    if (!isSupported) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Abandoned runs are not practice; they must not push the user towards
      // a prompt they have not earned.
      if (!isCompleted) return;

      final finished = (prefs.getInt(_finishedTestsKey) ?? 0) + 1;
      await prefs.setInt(_finishedTestsKey, finished);

      if (_askedThisSession) return;
      if (!isPassed) return;
      if (finished < minFinishedTests) return;

      final shown = prefs.getInt(_promptCountKey) ?? 0;
      if (shown >= maxPrompts) return;

      final lastMs = prefs.getInt(_lastPromptKey) ?? 0;
      if (lastMs != 0) {
        final since = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(lastMs),
        );
        if (since < promptInterval) return;
      }

      // No Play services (emulator, sideloaded build) — say nothing.
      if (!await _review.isAvailable()) return;

      // Written before the request, not after: if the sheet is shown and the
      // process dies while it is up, the ask still counts. Asking twice in a
      // row is worse than missing one ask.
      _askedThisSession = true;
      await prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_promptCountKey, shown + 1);

      await _review.requestReview();
    } catch (e) {
      debugPrint('ReviewPromptService.onTestFinished: $e');
    }
  }

  /// Opens the Play listing so the user can leave a review by hand.
  ///
  /// This is what the "rate the app" row in settings uses. It deliberately
  /// does NOT go through [InAppReview.requestReview]: a user who tapped a
  /// button expects something to happen, and the in-app sheet is allowed to
  /// show nothing at all.
  static Future<void> openStoreListing() async {
    try {
      await _review.openStoreListing();
    } catch (e) {
      debugPrint('ReviewPromptService.openStoreListing: $e');
      try {
        await launchUrl(
          Uri.parse(AppVersion.playStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        /* No browser and no Play — nothing useful to say. */
      }
    }
  }

  @visibleForTesting
  static void resetSessionFlagForTest() => _askedThisSession = false;
}
