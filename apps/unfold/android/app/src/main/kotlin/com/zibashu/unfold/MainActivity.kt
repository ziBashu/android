package com.zibashu.unfold

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.Bundle
import android.os.ParcelFileDescriptor
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.zibashu.unfold/native"
    private var channel: MethodChannel? = null
    private var pendingPick: MethodChannel.Result? = null
    private var pendingSave: MethodChannel.Result? = null
    private var pendingSaveBytes: ByteArray? = null
    private var incomingPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = ch
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "pick" -> {
                    pendingPick = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                    }
                    startActivityForResult(intent, REQ_PICK)
                }
                "share" -> {
                    val path = call.argument<String>("path")
                    val mime = call.argument<String>("mime") ?: "application/octet-stream"
                    if (path.isNullOrEmpty()) {
                        result.error("arg", "missing path", null)
                        return@setMethodCallHandler
                    }
                    val file = File(path)
                    if (!file.exists()) {
                        result.error("missing", path, null)
                        return@setMethodCallHandler
                    }
                    val uri = FileProvider.getUriForFile(this, "$packageName.files", file)
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = mime
                        putExtra(Intent.EXTRA_STREAM, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(Intent.createChooser(intent, "Share"))
                    result.success(true)
                }
                "saveAs" -> {
                    val name = call.argument<String>("name") ?: "unfold-export"
                    val mime = call.argument<String>("mime") ?: "application/octet-stream"
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null) {
                        result.error("arg", "missing bytes", null)
                        return@setMethodCallHandler
                    }
                    pendingSave = result
                    pendingSaveBytes = bytes
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = mime
                        putExtra(Intent.EXTRA_TITLE, name)
                    }
                    startActivityForResult(intent, REQ_SAVE)
                }
                "incoming" -> result.success(incomingPath)
                "renderPdfPage" -> {
                    val path = call.argument<String>("path")
                    val index = call.argument<Int>("index") ?: 0
                    val width = call.argument<Int>("width") ?: 720
                    if (path.isNullOrEmpty()) {
                        result.error("arg", "missing path", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(renderPdfPage(path, index, width))
                    } catch (e: Exception) {
                        result.error("pdf", e.message, null)
                    }
                }
                "pdfPageCount" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) {
                        result.error("arg", "missing path", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(pdfPageCount(path))
                    } catch (e: Exception) {
                        result.error("pdf", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        incomingPath?.let { ch.invokeMethod("open", it) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ingestIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        ingestIntent(intent)
        incomingPath?.let { channel?.invokeMethod("open", it) }
    }

    private fun ingestIntent(intent: Intent?) {
        if (intent == null) return
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW, Intent.ACTION_EDIT -> intent.data
            Intent.ACTION_SEND -> {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            else -> intent.data
        }
        if (uri != null) {
            incomingPath = copyUri(uri)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_PICK) {
            val r = pendingPick
            pendingPick = null
            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                r?.success(null)
                return
            }
            r?.success(copyUri(data.data!!))
            return
        }
        if (requestCode == REQ_SAVE) {
            val r = pendingSave
            val bytes = pendingSaveBytes
            pendingSave = null
            pendingSaveBytes = null
            if (resultCode != Activity.RESULT_OK || data?.data == null || bytes == null) {
                r?.success(false)
                return
            }
            try {
                contentResolver.openOutputStream(data.data!!)!!.use { it.write(bytes) }
                r?.success(true)
            } catch (e: Exception) {
                r?.error("save", e.message, null)
            }
        }
    }

    private fun copyUri(uri: Uri): String? {
        return try {
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            } catch (_: Exception) {
            }
            val raw = uri.lastPathSegment?.substringAfterLast('/') ?: "file-${System.currentTimeMillis()}"
            val name = raw.replace(Regex("[^A-Za-z0-9._-]"), "_")
            val dest = File(File(cacheDir, "imports").apply { mkdirs() }, name.ifEmpty { "open.bin" })
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(dest).use { output -> input.copyTo(output) }
            } ?: return null
            dest.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun pdfPageCount(path: String): Int {
        PdfRenderer(ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)).use { renderer ->
            return renderer.pageCount
        }
    }

    private fun renderPdfPage(path: String, index: Int, width: Int): ByteArray {
        PdfRenderer(ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)).use { renderer ->
            if (index < 0 || index >= renderer.pageCount) {
                throw IllegalArgumentException("page $index")
            }
            renderer.openPage(index).use { page ->
                val w = width.coerceIn(64, 2048)
                val h = ((w.toFloat() * page.height) / page.width).toInt().coerceAtLeast(1)
                val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                bmp.eraseColor(Color.WHITE)
                page.render(bmp, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                val out = ByteArrayOutputStream()
                bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
                bmp.recycle()
                return out.toByteArray()
            }
        }
    }

    companion object {
        private const val REQ_PICK = 81
        private const val REQ_SAVE = 82
    }
}
