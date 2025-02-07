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
                    val type = call.argument<String>("type")
                    if(type != null){
                        sendCommand(fileName, languageCommand, type)
                    }
                    result.success(null)
                }
                "closeTermux" -> {
                    closeTermux()
                }
                "installOnTermux" -> {
                    val packageName = call.argument<String>("packageName")
                    installOnTermux(packageName)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }


    /* private fun sendCommand(fileName: String?, languageCommand: String?){
        val (optionalArgs, extraCommand) = constructCommand(fileName, languageCommand)
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
    } */
    
    private fun sendCommand(fileName: String?, languageCommand: String?, type: String?) {
        val (optionalArgs, compiledFile, executable) = constructCommand(fileName, languageCommand)
        val intent = Intent()
        intent.setClassName("com.termux", "com.termux.app.RunCommandService")
        intent.action = "com.termux.RUN_COMMAND"
        intent.putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
        if(type == "compiled"){
            intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "/data/data/com.termux/files/usr/bin/rm -rf /data/data/com.termux/files/home/$executable && $optionalArgs /data/data/com.termux/files/usr/bin/$languageCommand $fileName 2>&1 | /data/data/com.termux/files/usr/bin/websocat -b ws://127.0.0.1:49258 && /data/data/com.termux/files/usr/bin/unbuffer -p /data/data/com.termux/files/usr/bin/websocat -b ws://127.0.0.1:49258 | /data/data/com.termux/files/usr/bin/unbuffer -p $compiledFile 2>&1 | /data/data/com.termux/files/usr/bin/websocat -b ws://127.0.0.1:49258"))
        }
        else if(type == "compiled(no binary)"){
            intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "/data/data/com.termux/files/usr/bin/unbuffer -p /data/data/com.termux/files/usr/bin/websocat -b ws://127.0.0.1:49258 | /data/data/com.termux/files/usr/bin/unbuffer -p /data/data/com.termux/files/usr/bin/$languageCommand $fileName 2>&1 | /data/data/com.termux/files/usr/bin/websocat -b ws://127.0.0.1:49258"))
        }
        else{
            intent.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "/data/data/com.termux/files/usr/bin/unbuffer -p /data/data/com.termux/files/usr/bin/websocat -b ws://127.0.0.1:49258 | /data/data/com.termux/files/usr/bin/$languageCommand $fileName 2>&1 | /data/data/com.termux/files/usr/bin/websocat -b ws://127.0.0.1:49258"))
        }
        intent.putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
        intent.putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
        intent.putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
        startService(intent)
    }

    private fun constructCommand(fileName: String?, languageCommand: String?): Triple<String?, String?, String?> {
        var optionalArgs = ""
        var compiledFile = ""
        var executable = ""

        when (languageCommand) {
            "javac" -> {
                executable = fileName!!.replaceLast(".java", ".class")
                val compiledFileName = fileName!!.replaceLast(".java", "").replaceLast("/"," ")
                compiledFile = "/data/data/com.termux/files/usr/bin/java -cp $compiledFileName"
            }
            "tsc" -> {
                optionalArgs = "/data/data/com.termux/files/usr/bin/node"
                val compiledFileName = fileName!!.replaceLast(".ts", ".js")
                executable = compiledFileName
                compiledFile = "/data/data/com.termux/files/usr/bin/node $compiledFileName"
            }
            "gcc", "g++" -> {
                compiledFile = "./a.out"
                executable = "a.out"
            }
            "rustc" -> {
                executable = fileName!!.substring(fileName!!.lastIndexOf("/") + 1).replaceLast(".rs", "")
                compiledFile = "./$executable"
            }
            "kotlinc" -> {
                val exec = fileName!!.substring(fileName!!.lastIndexOf("/") + 1).replaceLast(".kt", "").replaceFirstChar { it.uppercaseChar() } + "Kt"
                executable = exec + ".class"
                var path = "/data/data/com.termux/files/home/$exec"
                path = path.replaceLast("/", " ")
                compiledFile = "/data/data/com.termux/files/usr/bin/kotlin -cp $path"
            }
        }
        return Triple(optionalArgs, compiledFile, executable)
    }

    private fun closeTermux(){
        val intent = Intent().apply {
            setClassName("com.termux", "com.termux.app.RunCommandService")
            action = "com.termux.RUN_COMMAND"
            putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash")
            putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", "/data/data/com.termux/files/usr/bin/am startservice -a com.termux.service_stop com.termux/.app.TermuxService"))
            putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
            putExtra("com.termux.RUN_COMMAND_BACKGROUND", true)
            putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
        }
        startService(intent)
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
