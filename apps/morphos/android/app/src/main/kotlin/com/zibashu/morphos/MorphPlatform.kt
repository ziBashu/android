package com.zibashu.morphos

import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager

/**
 * Phase 6 — platform capability helpers (launcher role, battery, home, immersion).
 * Full custom ROM remains a long-term goal; this is the in-app platform layer.
 */
object MorphPlatform {

    fun platformInfo(context: Context): Map<String, Any?> {
        val pm = context.packageManager
        val isHome = isDefaultHome(context)
        val batteryOpt = isIgnoringBatteryOptimizations(context)
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "release" to Build.VERSION.RELEASE,
            "manufacturer" to (Build.MANUFACTURER ?: ""),
            "model" to (Build.MODEL ?: ""),
            "device" to (Build.DEVICE ?: ""),
            "isDefaultHome" to isHome,
            "ignoringBatteryOptimizations" to batteryOpt,
            "canWriteSettings" to Settings.System.canWrite(context),
            "canDrawOverlays" to Settings.canDrawOverlays(context),
            "accessibilityRunning" to MorphOrientationService.isRunning(),
            "systemMorphEnabled" to MorphOrientationStore.isEnabled(context),
            "globalOrientation" to MorphOrientationStore.globalMode(context),
            "packageName" to context.packageName,
            "hasHomeIntent" to true,
            "platformLayer" to "morphos-platform-v1",
            "romRoadmap" to false,
            "hasQsTile" to true,
            "hasBootRestore" to true,
            "features" to listOf(
                "home-launcher-candidate",
                "accessibility-orientation",
                "write-settings-rotation",
                "boot-restore",
                "qs-tile",
                "battery-opt-request",
                "system-ui-chrome",
            ),
            "versionLabel" to try {
                val info = if (Build.VERSION.SDK_INT >= 33) {
                    pm.getPackageInfo(
                        context.packageName,
                        PackageManager.PackageInfoFlags.of(0),
                    )
                } else {
                    @Suppress("DEPRECATION")
                    pm.getPackageInfo(context.packageName, 0)
                }
                info.versionName ?: ""
            } catch (_: Exception) {
                ""
            },
        )
    }

    fun isDefaultHome(context: Context): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            val res = context.packageManager.resolveActivity(
                intent,
                PackageManager.MATCH_DEFAULT_ONLY,
            )
            res?.activityInfo?.packageName == context.packageName
        } catch (_: Exception) {
            false
        }
    }

    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        return try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(context.packageName)
        } catch (_: Exception) {
            false
        }
    }

    fun openHomeSettings(context: Context): Boolean {
        return try {
            val intents = listOf(
                Intent(Settings.ACTION_HOME_SETTINGS),
                Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS),
                Intent(Settings.ACTION_SETTINGS),
            )
            for (intent in intents) {
                try {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    return true
                } catch (_: Exception) {
                    // try next
                }
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    fun openBatteryOptimizationSettings(context: Context): Boolean {
        return try {
            val intent = Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:${context.packageName}"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                context.startActivity(
                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    fun openAppDetails(context: Context): Boolean {
        return try {
            context.startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:${context.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    fun requestHomeRole(activity: Activity): Boolean {
        if (Build.VERSION.SDK_INT < 29) return openHomeSettings(activity)
        return try {
            val rm = activity.getSystemService(RoleManager::class.java)
            if (rm != null && rm.isRoleAvailable(RoleManager.ROLE_HOME) &&
                !rm.isRoleHeld(RoleManager.ROLE_HOME)
            ) {
                // Start from the Activity without NEW_TASK so the system
                // home/role picker associates correctly (LauncherOS-style).
                val intent = rm.createRequestRoleIntent(RoleManager.ROLE_HOME)
                activity.startActivity(intent)
                true
            } else if (rm != null && rm.isRoleHeld(RoleManager.ROLE_HOME)) {
                // Already home — open settings so user can confirm / switch.
                openHomeSettings(activity)
            } else {
                openHomeSettings(activity)
            }
        } catch (_: Exception) {
            openHomeSettings(activity)
        }
    }

    fun setKeepScreenOn(activity: Activity?, keep: Boolean) {
        val a = activity ?: return
        a.runOnUiThread {
            if (keep) {
                a.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                a.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }

}
