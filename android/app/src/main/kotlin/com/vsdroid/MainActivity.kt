package com.vsdroid

import android.os.Bundle
import android.content.pm.ApplicationInfo
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.arrayOf

fun String.replaceLast(oldValue: String, newValue: String): String {
    val lastIndex = this.lastIndexOf(oldValue)
    return if (lastIndex != -1) {
        this.substring(0, lastIndex) + newValue + this.substring(lastIndex + oldValue.length)
    } else {
        this
    }
}


class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.vsdroid"

    override fun configureFlutterEngine(@NonNull flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
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
                    sendCommand(fileName, languageCommand)
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
        var optionalArgs = ""
        var extraCommand = ""
        if(languageCommand == "javac"){
            var compiledFileName = fileName!!.replaceLast(".java","")
            compiledFileName = compiledFileName!!.replaceLast("/"," ")
            extraCommand = "&& /data/data/com.termux/files/usr/bin/java -cp $compiledFileName"
        }
        if(languageCommand == "tsc"){
            optionalArgs = "/data/data/com.termux/files/usr/bin/node"
            val compiledFileName = fileName!!.replaceLast(".ts",".js")
            extraCommand = "&& /data/data/com.termux/files/usr/bin/node $compiledFileName"
        }
        if(languageCommand == "gcc" || languageCommand == "g++"){
            extraCommand = "&& ./a.out"
        }
        if(languageCommand == "rustc"){
            val executable = fileName!!.substring(fileName.lastIndexOf("/") + 1).replaceLast(".rs", "")
            extraCommand = "&& ./$executable"
        }
        if(languageCommand == "kotlinc"){
            val executable = fileName!!.substring(fileName.lastIndexOf("/") + 1).replaceLast(".kt", "").replaceFirstChar { it.uppercaseChar() } + "Kt"
            var path = "/data/data/com.termux/files/home/$executable"
            path = path.replaceLast("/"," ")
            extraCommand = "&& /data/data/com.termux/files/usr/bin/java -cp $path"
        }
        val intent = Intent().apply {
            setClassName("com.termux", "com.termux.app.RunCommandService")
            action = "com.termux.RUN_COMMAND"
            putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "/data/data/com.termux/files/usr/bin/unbuffer $optionalArgs /data/data/com.termux/files/usr/bin/$languageCommand $fileName $extraCommand | /data/data/com.termux/files/usr/bin/websocat ws://127.0.0.1:49258"))
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
