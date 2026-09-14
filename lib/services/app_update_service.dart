import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_version.dart';

/// What Play knows about this install.
enum UpdateStatus {
  /// Not asked yet, or the answer is not usable (iOS, sideloaded, no Play).
  unknown,

  /// Play says this is the current version.
  upToDate,

  /// A newer version is published and can be installed.
  available,

  /// A flexible update finished downloading; it installs on the next restart.
  readyToInstall,
}

/// Tells the user when a newer build is waiting on Google Play, and installs
/// it without sending them out of the app.
///
/// WHY PLAY'S OWN API AND NOT A VERSION NUMBER IN THE DATABASE: Play is the
/// only thing that actually knows what has finished review, what is at what
/// rollout percentage, and whether *this* device is eligible. A number stored
/// somewhere else goes stale the moment a staged rollout is paused, and it
/// would tell users on an old Android that an update exists which Play will
/// never hand them.
///
/// Every call fails soft. An update prompt is a convenience; it must never be
/// the reason the app misbehaves.
class AppUpdateService {
  AppUpdateService._();

  /// Play's in-app update API is Android-only. Everywhere else this service
  /// reports [UpdateStatus.unknown] and shows nothing.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static UpdateStatus _status = UpdateStatus.unknown;
  static UpdateStatus get status => _status;

  /// Notifies when [status] changes, so a banner can appear without the
  /// screen having to poll.
  static final ValueNotifier<UpdateStatus> statusListenable =
      ValueNotifier<UpdateStatus>(UpdateStatus.unknown);

  static bool _checking = false;

  /// Asks Play whether a newer build is available.
  ///
  /// Safe to call on every app start and every time the profile screen opens;
  /// concurrent calls collapse into one.
  static Future<UpdateStatus> check() async {
    if (!isSupported || _checking) return _status;
    _checking = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      _set(switch (info.updateAvailability) {
        UpdateAvailability.updateAvailable => UpdateStatus.available,
        UpdateAvailability.developerTriggeredUpdateInProgress =>
          UpdateStatus.available,
        _ => UpdateStatus.upToDate,
      });
    } catch (e) {
      // Thrown on a sideloaded build, an emulator without Play, or no
      // network. None of those are the user's problem: say nothing.
      debugPrint('AppUpdateService.check: $e');
      _set(UpdateStatus.unknown);
    } finally {
      _checking = false;
    }
    return _status;
  }

  /// Runs Play's immediate-update flow: a full-screen Play dialog that
  /// downloads and installs, then restarts the app.
  ///
  /// Immediate rather than flexible because a stale question bank is the whole
  /// point of updating this app — a user who defers keeps practising on
  /// outdated answers without knowing it.
  ///
  /// Returns true when the update was started successfully. A cancelled or
  /// failed flow falls back to opening the Play Store listing, so the user is
  /// never left with a button that does nothing.
  static Future<bool> start() async {
    if (!isSupported) return openStorePage();
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.success) {
        _set(UpdateStatus.readyToInstall);
        return true;
      }
      // userDeniedUpdate — respect it, and leave the banner up.
      if (result == AppUpdateResult.userDeniedUpdate) return false;
      return openStorePage();
    } catch (e) {
      debugPrint('AppUpdateService.start: $e');
      return openStorePage();
    }
  }

  /// Last resort: hand the user to the Play Store listing.
  static Future<bool> openStorePage() async {
    try {
      return await launchUrl(
        Uri.parse(AppVersion.playStoreUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('AppUpdateService.openStorePage: $e');
      return false;
    }
  }

  static void _set(UpdateStatus next) {
    _status = next;
    statusListenable.value = next;
  }

  @visibleForTesting
  static void setStatusForTest(UpdateStatus status) => _set(status);
}
