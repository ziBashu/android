package com.zibashu.morphos

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
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
                    result.success(MorphPlatform.requestHomeRole(act))
                } else {
                    result.success(MorphPlatform.openHomeSettings(context))
                }
            }
            "setKeepScreenOn" -> {
                val keep = call.argument<Boolean>("keep") ?: false
                MorphPlatform.setKeepScreenOn(activityRef.get(), keep)
                result.success(true)
            }
            "cycleOrientationMode" -> {
                val modes = listOf(
                    "sensor",
                    "portrait",
                    "landscape",
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
            else -> result.notImplemented()
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
                "ignoringBatteryOptimizations" to false,
                "sdkInt" to 0,
                "manufacturer" to "",
                "model" to "",
            )
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
