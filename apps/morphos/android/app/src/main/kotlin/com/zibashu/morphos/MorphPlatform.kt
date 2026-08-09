package com.zibashu.morphos

import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager

/**
 * Platform helpers — default Home (third-party launcher) is ROLE_HOME / Settings,
 * not root. User must confirm; MorphOS only declares HOME and opens the system UI.
 */
object MorphPlatform {

    const val REQUEST_HOME_ROLE = 0x4D4F // 'MO'

    fun platformInfo(context: Context): Map<String, Any?> {
        val pm = context.packageManager
        val isHome = isDefaultHome(context)
        val batteryOpt = isIgnoringBatteryOptimizations(context)
        val homeProbe = probeHomeRegistration(context)
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "release" to Build.VERSION.RELEASE,
            "manufacturer" to (Build.MANUFACTURER ?: ""),
            "model" to (Build.MODEL ?: ""),
            "device" to (Build.DEVICE ?: ""),
            "isDefaultHome" to isHome,
            "isHomeCandidate" to (homeProbe["isHomeCandidate"] as? Boolean ?: false),
            "homeCandidateCount" to (homeProbe["homeCandidateCount"] ?: 0),
            "homeCandidates" to homeProbe["homeCandidates"],
            "ignoringBatteryOptimizations" to batteryOpt,
            "canWriteSettings" to Settings.System.canWrite(context),
            "canDrawOverlays" to Settings.canDrawOverlays(context),
            "accessibilityRunning" to MorphOrientationService.isRunning(),
            "systemMorphEnabled" to MorphOrientationStore.isEnabled(context),
            "globalOrientation" to MorphOrientationStore.globalMode(context),
            "packageName" to context.packageName,
            "hasHomeIntent" to true,
            "platformLayer" to "morphos-platform-v1.1",
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
            if (Build.VERSION.SDK_INT >= 29) {
                val rm = context.getSystemService(RoleManager::class.java)
                if (rm != null && rm.isRoleAvailable(RoleManager.ROLE_HOME) &&
                    rm.isRoleHeld(RoleManager.ROLE_HOME)
                ) {
                    return true
                }
            }
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

    /**
     * Whether PackageManager lists MorphOS as a HOME activity (the only
     * hard requirement for appearing in the system Home picker).
     */
    fun probeHomeRegistration(context: Context): Map<String, Any?> {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            val flags = if (Build.VERSION.SDK_INT >= 23) {
                PackageManager.MATCH_ALL
            } else {
                0
            }
            @Suppress("DEPRECATION")
            val list: List<ResolveInfo> =
                context.packageManager.queryIntentActivities(intent, flags)
            val names = list.mapNotNull { ri ->
                val pkg = ri.activityInfo?.packageName ?: return@mapNotNull null
                val act = ri.activityInfo?.name ?: ""
                "$pkg/$act"
            }
            val isCandidate = list.any {
                it.activityInfo?.packageName == context.packageName
            }
            mapOf(
                "isHomeCandidate" to isCandidate,
                "homeCandidateCount" to list.size,
                "homeCandidates" to names.take(24),
                "packageName" to context.packageName,
            )
        } catch (e: Exception) {
            mapOf(
                "isHomeCandidate" to false,
                "homeCandidateCount" to 0,
                "homeCandidates" to emptyList<String>(),
                "error" to (e.message ?: "probe failed"),
            )
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
        val intents = listOf(
            Intent(Settings.ACTION_HOME_SETTINGS),
            Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS),
            Intent(Settings.ACTION_APPLICATION_SETTINGS),
            Intent(Settings.ACTION_SETTINGS),
        )
        for (base in intents) {
            try {
                val intent = Intent(base)
                // Activity context: no NEW_TASK (better association). Application: need it.
                if (context !is Activity) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                return true
            } catch (_: Exception) {
                // try next
            }
        }
        return false
    }

    fun openBatteryOptimizationSettings(context: Context): Boolean {
        return try {
            val intent = Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:${context.packageName}"),
            )
            if (context !is Activity) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                if (context !is Activity) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    fun openAppDetails(context: Context): Boolean {
        return try {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${context.packageName}"),
            )
            if (context !is Activity) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    /**
     * Open the system UI so the user can choose MorphOS as Home.
     *
     * Android never allows silent takeover. Strategies (in order):
     * 1) RoleManager.ROLE_HOME request dialog (API 29+)
     * 2) Settings → Home app
     * 3) Default apps settings
     *
     * Returns a diagnostic map for the Flutter UI.
     */
    fun requestHomeRole(activity: Activity): Map<String, Any?> {
        val out = LinkedHashMap<String, Any?>()
        out.putAll(probeHomeRegistration(activity))
        out["isDefaultHome"] = isDefaultHome(activity)
        out["sdkInt"] = Build.VERSION.SDK_INT

        if (out["isDefaultHome"] == true) {
            out["action"] = "already_default"
            out["ok"] = true
            out["message"] = "MorphOS is already the default Home app."
            return out
        }

        if (out["isHomeCandidate"] != true) {
            // Manifest missing HOME — cannot appear in picker. Open app details as last resort.
            out["action"] = "not_a_home_candidate"
            out["ok"] = false
            out["message"] =
                "PackageManager does not list MorphOS as a Home app. Reinstall the APK."
            openAppDetails(activity)
            return out
        }

        // 1) RoleManager — the modern “Set as default Home?” system dialog.
        if (Build.VERSION.SDK_INT >= 29) {
            try {
                val rm = activity.getSystemService(RoleManager::class.java)
                out["roleAvailable"] = rm?.isRoleAvailable(RoleManager.ROLE_HOME) == true
                out["roleHeld"] = rm?.isRoleHeld(RoleManager.ROLE_HOME) == true
                if (rm != null &&
                    rm.isRoleAvailable(RoleManager.ROLE_HOME) &&
                    !rm.isRoleHeld(RoleManager.ROLE_HOME)
                ) {
                    val intent = rm.createRequestRoleIntent(RoleManager.ROLE_HOME)
                    // Prefer for-result so OEM UIs associate correctly.
                    @Suppress("DEPRECATION")
                    activity.startActivityForResult(intent, REQUEST_HOME_ROLE)
                    out["action"] = "role_request"
                    out["ok"] = true
                    out["message"] =
                        "Choose MorphOS in the system dialog, then press Home to verify."
                    return out
                }
            } catch (e: Exception) {
                out["roleError"] = e.message
            }
        }

        // 2) Settings → Home app (always works for third-party launchers).
        if (openHomeSettings(activity)) {
            out["action"] = "home_settings"
            out["ok"] = true
            out["message"] =
                "Opened system Home settings. Select MorphOS as the Home app."
            return out
        }

        out["action"] = "failed"
        out["ok"] = false
        out["message"] = "Could not open Home settings on this device."
        return out
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
