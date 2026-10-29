package com.hoffenuz.avtotestu

import android.content.Context
import android.net.ConnectivityManager
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
                when (call.method) {
                    "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                    // Trafikni tejash rejimi: yoqilgan bo'lsa savol videosi
                    // javobdan oldin oldindan yuklanmaydi (DataSaverService).
                    "dataSaver" -> result.success(isDataSaverOn())
                    else -> result.notImplemented()
                }
            }
    }

    // Faqat o'lchanadigan (mobil) tarmoqda va tizimda Data Saver yoqilganda true.
    private fun isDataSaverOn(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            cm.isActiveNetworkMetered &&
                cm.restrictBackgroundStatus == ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED
        } catch (_: Exception) {
            false
        }
    }
}
