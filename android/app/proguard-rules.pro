# R8 rules for the release build.
#
# Only the Java/Kotlin layer is shrunk here — all app logic is Dart, already
# AOT-compiled into libapp.so and untouched by R8. What remains is the Flutter
# engine glue plus the plugins (shared_preferences, url_launcher,
# webview_flutter, connectivity_plus), which are reached reflectively from the
# engine and must therefore be kept explicitly.

# ── Flutter engine and plugin registration ──
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ── Play Core ──
# NOW ACTUALLY USED, not just warned about: in_app_update talks to Play Core
# to offer the in-app update flow. R8 must not strip it, and the listener
# interfaces are called back into from Play services by reflection.
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
# Flutter deferred components reference classes this app does not ship.
-dontwarn com.google.android.play.core.**

# -- flutter_local_notifications --
# The plugin persists scheduled notifications as JSON through Gson and
# reconstructs them after a reboot. Obfuscating those model classes makes the
# daily question silently stop arriving after the first restart -- a failure
# that never shows up in a debug build.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn com.google.gson.**

# ── Keep annotations used for reflection by plugins ──
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# ── Native methods ──
-keepclasseswithmembernames class * {
    native <methods>;
}
