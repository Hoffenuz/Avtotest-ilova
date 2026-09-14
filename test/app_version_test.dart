import 'dart:io';

import 'package:avtotest_app/config/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

/// [AppVersion] is hand-written so the About section needs no plugin and no
/// await. That only stays honest if something checks it against the real
/// source — otherwise the app quietly reports the version it shipped with two
/// releases ago, and "check for updates" starts lying.
void main() {
  test('AppVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml has no `version: x.y.z+n`');
    expect(
      AppVersion.name,
      match!.group(1),
      reason: 'bump AppVersion.name in lib/config/app_version.dart too',
    );
    expect(
      AppVersion.code,
      int.parse(match.group(2)!),
      reason: 'bump AppVersion.code in lib/config/app_version.dart too',
    );
  });

  test('the Play Store link points at this app', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final match = RegExp(r'applicationId\s*=\s*"([^"]+)"').firstMatch(gradle);

    expect(match, isNotNull, reason: 'no applicationId in build.gradle.kts');
    expect(
      AppVersion.androidPackage,
      match!.group(1),
      reason: 'the store link would open a different app (or a 404)',
    );
    expect(AppVersion.playStoreUrl, contains(AppVersion.androidPackage));
  });

  test('the displayed version reads as a version', () {
    expect(AppVersion.displayVersion, startsWith('v'));
    expect(AppVersion.displayVersion, contains(AppVersion.name));
  });
}
