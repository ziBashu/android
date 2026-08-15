package com.zibashu.morphos

import android.content.Context
import android.os.Build
import android.os.Environment
import java.io.File

/**
 * Dual-write notes JSON.
 *
 * Switching the default Home app does **not** clear MorphOS app data.
 * We still write a Documents file so the user can see / copy the path.
 */
object MorphNotesIo {
    private const val FILE_NAME = "notes.json"
    private const val FOLDER = "MorphOS"

    fun paths(context: Context): Map<String, String> {
        val app = appFile(context)
        val pub = publicFile()
        return mapOf(
            "appPath" to app.absolutePath,
            "publicPath" to (pub?.absolutePath ?: ""),
        )
    }

    fun read(context: Context): String? {
        val pub = publicFile()
        if (pub != null && pub.isFile && pub.length() > 0) {
            try {
                return pub.readText(Charsets.UTF_8)
            } catch (_: Exception) {
            }
        }
        val app = appFile(context)
        if (app.isFile && app.length() > 0) {
            try {
                return app.readText(Charsets.UTF_8)
            } catch (_: Exception) {
            }
        }
        return null
    }

    fun write(context: Context, json: String): Map<String, String> {
        val app = appFile(context)
        try {
            app.parentFile?.mkdirs()
            app.writeText(json, Charsets.UTF_8)
        } catch (_: Exception) {
        }
        val pub = publicFile()
        if (pub != null) {
            try {
                pub.parentFile?.mkdirs()
                pub.writeText(json, Charsets.UTF_8)
            } catch (_: Exception) {
            }
        }
        return paths(context)
    }

    private fun appFile(context: Context): File {
        val ext = context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS)
        val dir = if (ext != null) File(ext, FOLDER) else File(context.filesDir, FOLDER)
        return File(dir, FILE_NAME)
    }

    @Suppress("DEPRECATION")
    private fun publicFile(): File? {
        return try {
            val docs = if (Build.VERSION.SDK_INT >= 29) {
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
            } else {
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
            }
            if (docs == null) return null
            File(File(docs, FOLDER), FILE_NAME)
        } catch (_: Exception) {
            null
        }
    }
}
