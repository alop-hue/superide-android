package com.vsdroid

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CORE_CHANNEL = "com.vsdroid"
    private val SAF_CHANNEL = "vsdroid/saf"
    private val PICK_DIR_REQUEST = 9001

    private var pendingSafResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CORE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLibraryPath" ->
                    result.success(applicationInfo.nativeLibraryDir)
                else ->
                    result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SAF_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "pickSafDir" -> {
                    if (pendingSafResult != null) {
                        result.error("BUSY", "Picker already active", null)
                        return@setMethodCallHandler
                    }
                    pendingSafResult = result
                    launchSafPicker()
                }

                "cloneSafDir" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr == null) {
                        result.error("NO_URI", "Missing SAF uri", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val path = cloneSafDir(Uri.parse(uriStr))
                        result.success(path)
                    } catch (e: Exception) {
                        result.error("CLONE_FAILED", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }


    private fun launchSafPicker() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            )
        }
        startActivityForResult(intent, PICK_DIR_REQUEST)
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != PICK_DIR_REQUEST) return

        val result = pendingSafResult
        pendingSafResult = null

        if (result == null || resultCode != Activity.RESULT_OK || data == null) {
            result?.success(null)
            return
        }

        val uri = data.data ?: run {
            result.success(null)
            return
        }

        contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION
        )

        result.success(uri.toString())
    }


    private fun cloneSafDir(treeUri: Uri): String {
        val src = DocumentFile.fromTreeUri(this, treeUri)
            ?: throw IllegalArgumentException("Invalid SAF tree URI")

        val projectsRoot = File("/data/data/com.vsdroid/VSdroid/Projects")
        if (!projectsRoot.exists()) projectsRoot.mkdirs()

        val target = File(projectsRoot, src.name ?: "ImportedProject")
        copySafRecursive(src, target)

        return target.absolutePath
    }

    private fun copySafRecursive(src: DocumentFile, dest: File) {
        if (src.isDirectory) {
            if (!dest.exists()) dest.mkdirs()
            src.listFiles().forEach { child ->
                val childDest = File(dest, child.name ?: "unknown")
                copySafRecursive(child, childDest)
            }
        } else {
            dest.parentFile?.let {
                if (!it.exists()) it.mkdirs()
            }
            contentResolver.openInputStream(src.uri)?.use { input ->
                dest.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
        }
    }
}
