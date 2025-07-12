package com.vsdroid

import android.os.Bundle
import android.content.pm.ApplicationInfo
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.arrayOf

/* fun String.replaceLast(oldValue: String, newValue: String): String {
    val lastIndex = this.lastIndexOf(oldValue)
    return if (lastIndex != -1) {
        this.substring(0, lastIndex) + newValue + this.substring(lastIndex + oldValue.length)
    } else {
        this
    }
} */


class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.vsdroid"

    override fun configureFlutterEngine(@NonNull flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLibraryPath" -> {
                    val nativeLibDir = applicationInfo.nativeLibraryDir
                    result.success(nativeLibDir)
                }
                else -> result.notImplemented()
            }
        }
    }
}
