package com.vsdroid

import android.os.Bundle
import android.content.pm.ApplicationInfo
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.arrayOf
import java.util.Timer
import java.util.TimerTask

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.vsdroid"

    override fun configureFlutterEngine(@NonNull flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        var intent: Intent? = null
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadLibrary" -> {
                    val libName = call.argument<String>("libName") ?: "libbash.so"
                    val nativeLibDir = applicationInfo.nativeLibraryDir
                    val fullPath = "$nativeLibDir/$libName"
                    result.success(fullPath)
                }
                "sendCommand" -> {
                    val fileName = call.argument<String>("fileName")
                    val languageCommand = call.argument<String>("languageCommand")
                    val projectType = call.argument<String>("projectType")
                    intent = sendCommand(fileName, languageCommand)
                    result.success(null)
                }
                "installOnTermux" -> {
                    val packageName = call.argument<String>("packageName")
                    installOnTermux(packageName)
                }
                else -> result.notImplemented()
            }
        }
    }


    private fun sendCommand(fileName: String?, languageCommand: String?): Intent {
        val intent = Intent().apply {
            setClassName("com.termux", "com.termux.app.RunCommandService")
            action = "com.termux.RUN_COMMAND"
            putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "/data/data/com.termux/files/usr/bin/unbuffer /data/data/com.termux/files/usr/bin/$languageCommand $fileName | /data/data/com.termux/files/usr/bin/websocat ws://127.0.0.1:49258"))
            putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
        }
        startService(intent)
        return intent
    }

    private fun installOnTermux(packageName: String?) {
        val intent = Intent().apply {
            setClassName("com.termux", "com.termux.app.RunCommandService")
            action = "com.termux.RUN_COMMAND"
            putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "/data/data/com.termux/files/usr/bin/pkg install $packageName | /data/data/com.termux/files/usr/bin/websocat ws://127.0.0.1:49258"))
            putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
        }
        startService(intent)
    }
}
