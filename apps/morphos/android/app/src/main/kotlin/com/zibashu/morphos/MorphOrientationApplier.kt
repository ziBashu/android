package com.zibashu.morphos

import android.content.Context
import android.provider.Settings
import android.view.Surface

/**
 * Applies system-wide screen orientation via Settings.System
 * (requires WRITE_SETTINGS / canWrite).
 *
 * Modes: portrait | landscape | reversePortrait | reverseLandscape | sensor | unlock
 */
object MorphOrientationApplier {
    fun canWrite(context: Context): Boolean =
        Settings.System.canWrite(context)

    fun apply(context: Context, mode: String): Boolean {
        if (!canWrite(context)) return false
        val cr = context.contentResolver
        return try {
            when (mode) {
                "sensor", "unlock", "auto" -> {
                    Settings.System.putInt(
                        cr,
                        Settings.System.ACCELEROMETER_ROTATION,
                        1,
                    )
                }
                else -> {
                    val rotation = when (mode) {
                        "portrait" -> Surface.ROTATION_0
                        "landscape" -> Surface.ROTATION_90
                        "reversePortrait" -> Surface.ROTATION_180
                        "reverseLandscape" -> Surface.ROTATION_270
                        else -> Surface.ROTATION_0
                    }
                    Settings.System.putInt(
                        cr,
                        Settings.System.ACCELEROMETER_ROTATION,
                        0,
                    )
                    Settings.System.putInt(
                        cr,
                        Settings.System.USER_ROTATION,
                        rotation,
                    )
                }
            }
            MorphOrientationStore.setLastMode(context, mode)
            true
        } catch (_: SecurityException) {
            false
        } catch (_: Exception) {
            false
        }
    }

    fun resolveModeForPackage(context: Context, packageName: String?): String {
        if (packageName.isNullOrBlank()) {
            return MorphOrientationStore.globalMode(context)
        }
        // Don't lock MorphOS itself to a stale external rule.
        if (packageName == context.packageName) {
            return MorphOrientationStore.globalMode(context)
        }
        val rules = MorphOrientationStore.packageRules(context)
        return rules[packageName] ?: MorphOrientationStore.globalMode(context)
    }
}
