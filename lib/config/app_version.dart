/// The version this build reports to the user.
///
/// Kept as constants rather than read at runtime so nothing has to be
/// awaited to render the About section, and so there is no extra plugin in
/// the tree for two strings. `test/app_version_test.dart` reads pubspec.yaml
/// and fails if these drift from it, which is the only way this can go wrong.
class AppVersion {
  AppVersion._();

  /// `version:` in pubspec.yaml, before the `+`.
  static const String name = '1.0.12';

  /// `version:` in pubspec.yaml, after the `+` — Android's versionCode.
  static const int code = 12;

  static String get displayVersion => 'v$name';

  /// `applicationId` from android/app/build.gradle.kts.
  static const String androidPackage = 'com.hoffenuz.Avtotestu';

  /// Play Store listing, used as the fallback when the in-app update flow is
  /// unavailable (a sideloaded build, or Play services missing).
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackage';
}
