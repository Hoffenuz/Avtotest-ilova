import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a payment link straight in the provider's own app (Payme, Click)
/// when one on the phone claims it — paying there is a tap with a saved card.
///
/// Returns false, having opened NOTHING, when no app takes the link; the
/// caller then uses the in-app checkout exactly as before. A browser is never
/// the result: that would strand the user outside the app with the return
/// page, which is worse than the in-app checkout.
class ProviderAppLauncher {
  ProviderAppLauncher._();

  static const MethodChannel _platform = MethodChannel('avtotestu/platform');

  static Future<bool> tryOpen(String url) async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      // "Apps only, never a browser" exists from Android 11 (API 30); before
      // that the same call would open the browser.
      if (await _androidSdk() < 30) return false;
    } else if (!Platform.isIOS) {
      return false;
    }
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<int> _androidSdk() async {
    try {
      return await _platform.invokeMethod<int>('sdkInt') ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
