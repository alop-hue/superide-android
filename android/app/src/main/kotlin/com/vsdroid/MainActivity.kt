package com.vsdroid

import android.os.Bundle
import android.content.pm.ApplicationInfo
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.arrayOf

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
            if (call.method == "sendCommand") {
                val fileName=call.argument<String>("fileName")
                val languageCommand=call.argument<String>("languageCommand")
                val projectType = call.argument<String>("projectType")
                sendCommand(fileName,languageCommand)
                result.success(null)
            } else {
                result.notImplemented()
            }
            if(call.method == "sendOperations"){
            val operation = call.argument<String>("operation")
                val arguments = call.argument<String>("arguments")
                sendOperations(operation, arguments)
            }
        }
    }

    private fun sendCommand(fileName:String?,languageCommand:String?){
        val intent = Intent()
        intent.setClassName("com.termux", "com.termux.app.RunCommandService")
        intent.setAction("com.termux.RUN_COMMAND")
        intent.putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/$languageCommand")
        intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(fileName))
        intent.putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
        intent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", false)
        intent.putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
        startService(intent)
    }

    private fun sendOperations(operation:String?,arguments:String?){
        val intent = Intent()
        intent.setClassName("com.termux", "com.termux.app.RunCommandService")
        intent.setAction("com.termux.RUN_COMMAND")
        intent.putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/home/a.out")
        // intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf(arguments))
        intent.putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
        intent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", false)
        intent.putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
        startService(intent)
    }
}
