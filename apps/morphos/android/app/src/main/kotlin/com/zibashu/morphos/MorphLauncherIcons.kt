package com.zibashu.morphos

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream

/** Rasterize the real MAIN+LAUNCHER icon for a package (not a generic glyph). */
object MorphLauncherIcons {
    fun pngFor(context: Context, packageName: String, size: Int = 96): ByteArray? {
        if (packageName.isBlank()) return null
        return try {
            val pm = context.packageManager
            val drawable = launcherDrawable(pm, packageName) ?: return null
            val bmp = drawableToBitmap(drawable, size)
            val out = ByteArrayOutputStream()
            bmp.compress(Bitmap.CompressFormat.PNG, 92, out)
            if (!bmp.isRecycled) bmp.recycle()
            out.toByteArray()
        } catch (_: Exception) {
            null
        }
    }

    fun batch(context: Context, packages: List<String>, size: Int = 96): Map<String, ByteArray> {
        val out = LinkedHashMap<String, ByteArray>()
        for (pkg in packages) {
            if (pkg.isBlank() || out.containsKey(pkg)) continue
            val bytes = pngFor(context, pkg, size) ?: continue
            if (bytes.isEmpty() || bytes.size > 180 * 1024) continue
            out[pkg] = bytes
        }
        return out
    }

    private fun launcherDrawable(pm: PackageManager, packageName: String): Drawable? {
        val intent = Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .setPackage(packageName)
        val resolved = try {
            pm.queryIntentActivities(intent, 0)
        } catch (_: Exception) {
            emptyList()
        }
        val ri = resolved.firstOrNull()
        if (ri != null) {
            try {
                val icon = ri.loadIcon(pm)
                if (icon != null) return icon
            } catch (_: Exception) {
            }
            try {
                val icon = ri.activityInfo?.loadIcon(pm)
                if (icon != null) return icon
            } catch (_: Exception) {
            }
        }
        return try {
            pm.getApplicationIcon(packageName)
        } catch (_: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable, size: Int): Bitmap {
        if (drawable is BitmapDrawable) {
            val src = drawable.bitmap
            if (src != null && !src.isRecycled) {
                return Bitmap.createScaledBitmap(src, size, size, true)
            }
        }
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        return bmp
    }
}
