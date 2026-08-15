package com.zibashu.morphos

import android.Manifest
import android.app.Activity
import android.app.SearchManager
import android.app.WallpaperManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.hardware.display.DisplayManager
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Display
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

/**
 * MethodChannel bridge: Flutter ↔ native morph + platform layer.
 * Channel: com.zibashu.morphos/system
 */
class MorphSystemBridge(
    private val context: Context,
    activity: Activity? = null,
) : MethodChannel.MethodCallHandler {

    private val activityRef = WeakReference(activity)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> result.success(statusMap())
            "getPlatformInfo" -> result.success(MorphPlatform.platformInfo(context))
            "setSystemMorphEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                MorphOrientationStore.setEnabled(context, enabled)
                if (enabled) {
                    MorphOrientationService.reapply(context)
                } else {
                    MorphOrientationApplier.apply(context, "sensor")
                }
                result.success(statusMap())
            }
            "setGlobalOrientation" -> {
                val mode = call.argument<String>("mode") ?: "sensor"
                MorphOrientationStore.setGlobalMode(context, mode)
                val applied = if (MorphOrientationStore.isEnabled(context)) {
                    MorphOrientationApplier.apply(context, mode)
                } else {
                    false
                }
                result.success(applied)
            }
            "applyGlobalOrientationNow" -> {
                val mode = call.argument<String>("mode") ?: "sensor"
                MorphOrientationStore.setGlobalMode(context, mode)
                MorphOrientationStore.setEnabled(context, true)
                val applied = MorphOrientationApplier.apply(context, mode)
                MorphOrientationService.reapply(context)
                result.success(applied)
            }
            "testRotationPulse" -> {
                MorphOrientationStore.setEnabled(context, true)
                val ok = MorphOrientationApplier.apply(context, "landscape")
                MorphOrientationStore.setGlobalMode(context, "landscape")
                result.success(if (ok) "landscape" else null)
            }
            "syncPackageRules" -> {
                @Suppress("UNCHECKED_CAST")
                val raw = call.argument<Map<String, Any?>>("rules")
                    ?: emptyMap()
                val rules = raw.mapNotNull { (k, v) ->
                    val mode = v?.toString()
                    if (k.isNotBlank() && mode != null) k to mode else null
                }.toMap()
                MorphOrientationStore.setPackageRules(context, rules)
                MorphOrientationService.reapply(context)
                result.success(rules.size)
            }
            "openAccessibilitySettings" -> {
                result.success(openSettings(Settings.ACTION_ACCESSIBILITY_SETTINGS))
            }
            "openWriteSettings" -> {
                try {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_WRITE_SETTINGS,
                        Uri.parse("package:${context.packageName}"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("open", e.message, null)
                }
            }
            "openOverlaySettings" -> {
                try {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${context.packageName}"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("open", e.message, null)
                }
            }
            "openHomeSettings" -> result.success(MorphPlatform.openHomeSettings(context))
            "openBatteryOptimizationSettings" ->
                result.success(MorphPlatform.openBatteryOptimizationSettings(context))
            "openAppDetails" -> result.success(MorphPlatform.openAppDetails(context))
            "requestHomeRole" -> {
                val act = activityRef.get()
                if (act != null) {
                    // Map with action / isHomeCandidate / message for Flutter UI.
                    result.success(MorphPlatform.requestHomeRole(act))
                } else {
                    val ok = MorphPlatform.openHomeSettings(context)
                    result.success(
                        mapOf(
                            "ok" to ok,
                            "action" to if (ok) "home_settings" else "failed",
                            "message" to if (ok) {
                                "Opened Home settings"
                            } else {
                                "No activity; could not open Home settings"
                            },
                            "isDefaultHome" to MorphPlatform.isDefaultHome(context),
                        ) + MorphPlatform.probeHomeRegistration(context),
                    )
                }
            }
            "probeHomeRegistration" -> {
                result.success(MorphPlatform.probeHomeRegistration(context))
            }
            "setKeepScreenOn" -> {
                val keep = call.argument<Boolean>("keep") ?: false
                MorphPlatform.setKeepScreenOn(activityRef.get(), keep)
                result.success(true)
            }
            "moveTaskToBack" -> {
                // Launcher root: never finish; send MorphOS behind other apps.
                val act = activityRef.get()
                val ok = try {
                    act?.moveTaskToBack(true) ?: false
                } catch (_: Exception) {
                    false
                }
                result.success(ok)
            }
            "isHomeIntent" -> {
                result.success(MainActivity.isHomeIntent(activityRef.get()?.intent))
            }
            "queryLauncherApps" -> result.success(queryLauncherApps())
            "getLauncherIcons" -> {
                val pkgs = call.argument<List<Any?>>("packages")
                    ?.mapNotNull { it?.toString() }
                    ?.filter { it.isNotBlank() }
                    ?: emptyList()
                result.success(MorphLauncherIcons.batch(context, pkgs))
            }
            "getLauncherIcon" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                result.success(MorphLauncherIcons.pngFor(context, pkg))
            }
            "notesPaths" -> result.success(MorphNotesIo.paths(context))
            "readNotesJson" -> result.success(MorphNotesIo.read(context))
            "writeNotesJson" -> {
                val json = call.argument<String>("json") ?: "[]"
                result.success(MorphNotesIo.write(context, json))
            }
            "openWebSearch" -> {
                val q = call.argument<String>("query") ?: ""
                result.success(openWebSearch(q))
            }
            "getDefaultBrowser" -> result.success(defaultBrowser())
            "getLastLocation" -> result.success(lastLocation())
            "requestLocationPermission" -> result.success(requestLocationPermission())
            "getBatteryExtras" -> result.success(batteryExtras())
            "setSystemWallpaper" -> {
                val bytes = call.argument<ByteArray>("bytes")
                result.success(setSystemWallpaper(bytes))
            }
            "requestUninstall" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                result.success(requestUninstall(pkg))
            }
            "cycleOrientationMode" -> {
                val modes = listOf(
                    "sensor",
                    "portrait",
                    "landscape",
                    "reversePortrait",
                    "reverseLandscape",
                )
                val current = MorphOrientationStore.globalMode(context)
                val idx = modes.indexOf(current).let { if (it < 0) 0 else it }
                val next = modes[(idx + 1) % modes.size]
                MorphOrientationStore.setGlobalMode(context, next)
                MorphOrientationStore.setEnabled(context, true)
                MorphOrientationApplier.apply(context, next)
                result.success(next)
            }
            "getDisplayInfo" -> result.success(displayInfo())
            "openAppInfo" -> {
                val pkg = call.argument<String>("packageName") ?: ""
                result.success(MorphQs.openAppInfo(context, pkg))
            }
            "runShortcut" -> {
                val action = call.argument<String>("action") ?: ""
                val pkg = call.argument<String>("packageName") ?: ""
                result.success(MorphQs.runShortcut(context, action, pkg))
            }
            "getShadeSnapshot" -> result.success(MorphQs.snapshot(context))
            "toggleShadeTile" -> {
                val id = call.argument<String>("id") ?: ""
                result.success(MorphQs.toggle(context, id))
            }
            "setBrightness" -> {
                val value = (call.argument<Number>("value") ?: 0.5).toDouble()
                result.success(MorphQs.setBrightness(context, value))
            }
            "islandCommand" -> {
                val cmd = call.argument<String>("command") ?: ""
                result.success(MorphQs.islandCommand(context, cmd))
            }
            "getIslandSnapshot" -> result.success(MorphQs.islandSnapshot(context))
            "syncChrome" -> {
                val sidebar = call.argument<Boolean>("sidebar") ?: true
                val shade = call.argument<Boolean>("notificationBar") ?: true
                val island = call.argument<Boolean>("smartIsland") ?: true
                @Suppress("UNCHECKED_CAST")
                val shortcuts = (call.argument<List<Any?>>("shortcuts")
                    ?: emptyList())
                    .mapNotNull { it?.toString() }
                MorphChromeService.sync(context, sidebar, shade, island, shortcuts)
                result.success(true)
            }
            "setHomeVisible" -> {
                val visible = call.argument<Boolean>("visible") ?: false
                MorphChromeService.setHomeVisible(context, visible)
                result.success(true)
            }
            "openNotificationListenerSettings" -> {
                result.success(
                    try {
                        context.startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        true
                    } catch (_: Exception) {
                        false
                    },
                )
            }
            else -> result.notImplemented()
        }
    }

    private fun queryLauncherApps(): List<Map<String, Any?>> {
        return try {
            val pm = context.packageManager
            val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            val flags = if (Build.VERSION.SDK_INT >= 23) {
                PackageManager.MATCH_ALL
            } else {
                0
            }
            val resolves = pm.queryIntentActivities(intent, flags)
            resolves.mapNotNull { ri ->
                val info = ri.activityInfo ?: return@mapNotNull null
                val pkg = info.packageName ?: return@mapNotNull null
                val label = try {
                    ri.loadLabel(pm)?.toString()?.trim().orEmpty()
                } catch (_: Exception) {
                    ""
                }
                mapOf(
                    "packageName" to pkg,
                    "activity" to info.name,
                    "label" to label,
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    @Suppress("DEPRECATION")
    private fun batteryExtras(): Map<String, Any?> {
        return try {
            val intent = context.registerReceiver(
                null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED),
            )
            if (intent == null) {
                emptyMap()
            } else {
                MorphBatteryStream.extrasFrom(intent)
            }
        } catch (_: Exception) {
            emptyMap()
        }
    }

    private fun setSystemWallpaper(bytes: ByteArray?): Boolean {
        if (bytes == null || bytes.isEmpty()) return false
        return try {
            val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return false
            val wm = WallpaperManager.getInstance(context)
            if (Build.VERSION.SDK_INT >= 24) {
                wm.setBitmap(bmp, null, true, WallpaperManager.FLAG_SYSTEM)
            } else {
                @Suppress("DEPRECATION")
                wm.setBitmap(bmp)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun requestUninstall(packageName: String): Boolean {
        if (packageName.isBlank()) return false
        return try {
            val intent = Intent(
                Intent.ACTION_DELETE,
                Uri.parse("package:$packageName"),
            )
            val act = activityRef.get()
            if (act != null) {
                act.startActivity(intent)
            } else {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openSettings(action: String): Boolean {
        return try {
            context.startActivity(
                Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun statusMap(): Map<String, Any?> {
        return try {
            val info = displayInfo()
            val platform = MorphPlatform.platformInfo(context)
            mapOf(
                "systemMorphEnabled" to MorphOrientationStore.isEnabled(context),
                "accessibilityRunning" to MorphOrientationService.isRunning(),
                "accessibilityEnabled" to
                    MorphOrientationService.isEnabledInSettings(context),
                "canWriteSettings" to MorphOrientationApplier.canWrite(context),
                "canDrawOverlays" to Settings.canDrawOverlays(context),
                "globalOrientation" to MorphOrientationStore.globalMode(context),
                "lastForegroundPackage" to
                    (MorphOrientationStore.lastForeground(context) ?: ""),
                "lastAppliedMode" to
                    (MorphOrientationStore.lastMode(context) ?: ""),
                "lastApplyOk" to MorphOrientationApplier.canWrite(context),
                "displayCount" to (info["displayCount"] ?: 1),
                "hasExternalDisplay" to (info["hasExternalDisplay"] ?: false),
                "isDefaultHome" to (platform["isDefaultHome"] ?: false),
                "isHomeCandidate" to (platform["isHomeCandidate"] ?: false),
                "homeCandidateCount" to (platform["homeCandidateCount"] ?: 0),
                "ignoringBatteryOptimizations" to
                    (platform["ignoringBatteryOptimizations"] ?: false),
                "sdkInt" to (platform["sdkInt"] ?: 0),
                "manufacturer" to (platform["manufacturer"] ?: ""),
                "model" to (platform["model"] ?: ""),
            )
        } catch (_: Exception) {
            mapOf(
                "systemMorphEnabled" to false,
                "accessibilityRunning" to false,
                "accessibilityEnabled" to false,
                "canWriteSettings" to false,
                "canDrawOverlays" to false,
                "globalOrientation" to "sensor",
                "lastForegroundPackage" to "",
                "lastAppliedMode" to "",
                "lastApplyOk" to false,
                "displayCount" to 1,
                "hasExternalDisplay" to false,
                "isDefaultHome" to false,
                "isHomeCandidate" to false,
                "homeCandidateCount" to 0,
                "ignoringBatteryOptimizations" to false,
                "sdkInt" to 0,
                "manufacturer" to "",
                "model" to "",
            )
        }
    }

    private fun openWebSearch(query: String): Boolean {
        val q = query.trim()
        if (q.isEmpty()) return false
        val starter = activityRef.get() ?: context
        val webSearch = Intent(Intent.ACTION_WEB_SEARCH)
            .putExtra(SearchManager.QUERY, q)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            starter.startActivity(webSearch)
            true
        } catch (_: Exception) {
            try {
                val uri = Uri.parse(
                    "https://www.google.com/search?q=${Uri.encode(q)}",
                )
                starter.startActivity(
                    Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun defaultBrowser(): Map<String, String> {
        return try {
            val view = Intent(Intent.ACTION_VIEW, Uri.parse("https://"))
            val ri = context.packageManager.resolveActivity(view, PackageManager.MATCH_DEFAULT_ONLY)
            val pkg = ri?.activityInfo?.packageName.orEmpty()
            val label = try {
                ri?.loadLabel(context.packageManager)?.toString().orEmpty()
            } catch (_: Exception) {
                ""
            }
            mapOf("packageName" to pkg, "label" to label)
        } catch (_: Exception) {
            mapOf("packageName" to "", "label" to "")
        }
    }

    private fun requestLocationPermission(): Boolean {
        val act = activityRef.get() ?: return false
        return try {
            if (Build.VERSION.SDK_INT < 23) return true
            if (context.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
            ) {
                return true
            }
            act.requestPermissions(
                arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION),
                72,
            )
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun lastLocation(): Map<String, Any?> {
        val granted = if (Build.VERSION.SDK_INT < 23) {
            true
        } else {
            context.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED ||
                context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
        }
        if (!granted) {
            return mapOf(
                "ok" to false,
                "needPermission" to true,
            )
        }
        return try {
            val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val loc = try {
                lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            } catch (_: Exception) {
                null
            } ?: try {
                lm.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            } catch (_: Exception) {
                null
            } ?: try {
                if (Build.VERSION.SDK_INT >= 31) {
                    lm.getLastKnownLocation(LocationManager.FUSED_PROVIDER)
                } else {
                    null
                }
            } catch (_: Exception) {
                null
            }
            if (loc == null) {
                mapOf("ok" to false, "needPermission" to false)
            } else {
                mapOf(
                    "ok" to true,
                    "needPermission" to false,
                    "latitude" to loc.latitude,
                    "longitude" to loc.longitude,
                )
            }
        } catch (_: Exception) {
            mapOf("ok" to false, "needPermission" to false)
        }
    }

    private fun displayInfo(): Map<String, Any?> {
        return try {
            val dm =
                context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            val displays = dm.displays
            val external = displays.any { d ->
                d.displayId != Display.DEFAULT_DISPLAY && d.state == Display.STATE_ON
            }
            val names = displays.map { d ->
                val size = try {
                    Pair(d.mode.physicalWidth, d.mode.physicalHeight)
                } catch (_: Exception) {
                    Pair(0, 0)
                }
                mapOf(
                    "id" to d.displayId,
                    "name" to
                        (if (Build.VERSION.SDK_INT >= 30) {
                            d.name ?: "display-${d.displayId}"
                        } else {
                            "display-${d.displayId}"
                        }),
                    "isDefault" to (d.displayId == Display.DEFAULT_DISPLAY),
                    "state" to d.state,
                    "width" to size.first,
                    "height" to size.second,
                )
            }
            mapOf(
                "displayCount" to displays.size,
                "hasExternalDisplay" to external,
                "displays" to names,
            )
        } catch (_: Exception) {
            mapOf(
                "displayCount" to 1,
                "hasExternalDisplay" to false,
                "displays" to emptyList<Map<String, Any?>>(),
            )
        }
    }
}
