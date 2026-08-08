package com.zibashu.morphos

import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Display
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MethodChannel bridge: Flutter ↔ native system morph + desktop display info.
 * Channel: com.zibashu.morphos/system
 */
class MorphSystemBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> result.success(statusMap())
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
                if (MorphOrientationStore.isEnabled(context)) {
                    MorphOrientationApplier.apply(context, mode)
                }
                result.success(true)
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
                try {
                    context.startActivity(
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK,
                        ),
                    )
                    result.success(true)
                } catch (e: Exception) {
                    result.error("open", e.message, null)
                }
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
            "getDisplayInfo" -> result.success(displayInfo())
            else -> result.notImplemented()
        }
    }

    private fun statusMap(): Map<String, Any?> {
        val enabled = MorphOrientationStore.isEnabled(context)
        return mapOf(
            "systemMorphEnabled" to enabled,
            "accessibilityRunning" to MorphOrientationService.isRunning(),
            "canWriteSettings" to MorphOrientationApplier.canWrite(context),
            "canDrawOverlays" to Settings.canDrawOverlays(context),
            "globalOrientation" to MorphOrientationStore.globalMode(context),
            "lastForegroundPackage" to MorphOrientationStore.lastForeground(context),
            "lastAppliedMode" to MorphOrientationStore.lastMode(context),
            "displayCount" to displayInfo()["displayCount"],
            "hasExternalDisplay" to displayInfo()["hasExternalDisplay"],
        )
    }

    private fun displayInfo(): Map<String, Any?> {
        val dm = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        val displays = dm.displays
        val external = displays.any { d ->
            d.displayId != Display.DEFAULT_DISPLAY && d.state == Display.STATE_ON
        }
        val names = displays.map { d ->
            mapOf(
                "id" to d.displayId,
                "name" to (if (Build.VERSION.SDK_INT >= 30) d.name else "display-${d.displayId}"),
                "isDefault" to (d.displayId == Display.DEFAULT_DISPLAY),
                "state" to d.state,
                "width" to d.mode?.physicalWidth,
                "height" to d.mode?.physicalHeight,
            )
        }
        return mapOf(
            "displayCount" to displays.size,
            "hasExternalDisplay" to external,
            "displays" to names,
        )
    }
}
