package com.hoffenuz.avtotestu

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The Android version, so the payment screen knows whether it can ask
        // for "open in an app, never in a browser" (API 30+ only).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "avtotestu/platform")
            .setMethodCallHandler { call, result ->
                if (call.method == "sdkInt") {
                    result.success(Build.VERSION.SDK_INT)
                } else {
                    result.notImplemented()
                }
            }
    }
}
