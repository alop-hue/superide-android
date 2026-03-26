package com.roxum

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import androidx.annotation.NonNull
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CORE_CHANNEL = "com.roxum"
    private val SAF_CHANNEL = "roxum/saf"
    private val PICK_DIR_REQUEST = 9001

    private var pendingSafResult: MethodChannel.Result? = null
    private val pendingOpenFiles = mutableListOf<String>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CORE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLibraryPath" ->
                    result.success(applicationInfo.nativeLibraryDir)
                "consumePendingOpenFiles" -> {
                    val files = pendingOpenFiles.toList()
                    pendingOpenFiles.clear()
                    result.success(files)
                }
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

        val projectsRoot = File("/data/data/com.roxum/Roxum/Projects")
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

    private fun handleIncomingIntent(intent: Intent?) {
        if (intent == null) return

        val action = intent.action ?: return
        val uris = mutableListOf<Uri>()

        when (action) {
            Intent.ACTION_VIEW -> {
                intent.data?.let { uris.add(it) }
            }

            Intent.ACTION_SEND -> {
                val streamUri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                if (streamUri != null) {
                    uris.add(streamUri)
                } else {
                    intent.data?.let { uris.add(it) }
                }
            }

            Intent.ACTION_SEND_MULTIPLE -> {
                val list = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                if (list != null) {
                    uris.addAll(list)
                }
            }
        }

        if (uris.isEmpty()) return

        uris.forEach { uri ->
            grantReadPermissionIfNeeded(intent, uri)
            val importedPath = importUriToAppFile(uri)
            if (importedPath != null) {
                pendingOpenFiles.add(importedPath)
            }
        }
    }

    private fun grantReadPermissionIfNeeded(intent: Intent, uri: Uri) {
        val flags = intent.flags
        val hasReadPermission =
            (flags and Intent.FLAG_GRANT_READ_URI_PERMISSION) == Intent.FLAG_GRANT_READ_URI_PERMISSION
        if (!hasReadPermission) return

        try {
            contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } catch (_: SecurityException) {
        }
    }

    private fun importUriToAppFile(uri: Uri): String? {
        val targetRoot = File("/data/data/$packageName/Roxum/Files")
        if (!targetRoot.exists()) targetRoot.mkdirs()

        val preferredName = queryDisplayName(uri)
            ?: uri.lastPathSegment
            ?: "shared_file"
        val sanitizedName = preferredName.replace('/', '_')
        val targetFile = buildUniqueFile(targetRoot, sanitizedName)

        return try {
            contentResolver.openInputStream(uri)?.use { input ->
                targetFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            } ?: return null
            targetFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index != -1 && cursor.moveToFirst()) {
                    cursor.getString(index)
                } else {
                    null
                }
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun buildUniqueFile(directory: File, baseName: String): File {
        val dotIndex = baseName.lastIndexOf('.')
        val name = if (dotIndex > 0) baseName.substring(0, dotIndex) else baseName
        val ext = if (dotIndex > 0) baseName.substring(dotIndex) else ""

        var candidate = File(directory, "$name$ext")
        var i = 1
        while (candidate.exists()) {
            candidate = File(directory, "$name-$i$ext")
            i++
        }
        return candidate
    }
}
