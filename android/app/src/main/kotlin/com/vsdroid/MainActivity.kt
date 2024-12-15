package com.vsdroid

import android.os.Bundle
import android.content.pm.ApplicationInfo
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vsdroid"

    override fun configureFlutterEngine(@NonNull flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "loadLibrary") {
                val libName = call.argument<String>("libName") ?: "libbash.so"
                val nativeLibDir = applicationInfo.nativeLibraryDir
                val fullPath = "$nativeLibDir/$libName"
                result.success(fullPath)
            } else {
                result.notImplemented()
            }
        }
    }
}
