package com.zibashu.morphos

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * Phase 2+ system morph orientation.
 * Detects foreground package (Rotation-style) and applies orientation rules.
 */
class MorphOrientationService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "MorphOrientationService connected")
        if (MorphOrientationStore.isEnabled(this)) {
            val mode = MorphOrientationStore.globalMode(this)
            MorphOrientationApplier.apply(this, mode)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (!MorphOrientationStore.isEnabled(this)) return

        val type = event.eventType
        if (type != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            type != AccessibilityEvent.TYPE_WINDOWS_CHANGED
        ) {
            return
        }

        val pkg = event.packageName?.toString()
        if (pkg.isNullOrBlank()) return
        // Ignore system UI chrome spam.
        if (pkg == "com.android.systemui") return

        MorphOrientationStore.setLastForeground(this, pkg)
        val mode = MorphOrientationApplier.resolveModeForPackage(this, pkg)
        val ok = MorphOrientationApplier.apply(this, mode)
        Log.d(TAG, "fg=$pkg mode=$mode applied=$ok")
    }

    override fun onInterrupt() {
        // no-op
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        super.onDestroy()
    }

    companion object {
        private const val TAG = "MorphOrientationSvc"
        @Volatile
        var instance: MorphOrientationService? = null
            private set

        fun isRunning(): Boolean = instance != null

        /** True when user enabled MorphOS in system Accessibility settings. */
        fun isEnabledInSettings(context: Context): Boolean {
            return try {
                val expected = ComponentName(
                    context,
                    MorphOrientationService::class.java,
                ).flattenToString()
                val enabled = Settings.Secure.getString(
                    context.contentResolver,
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                ) ?: return false
                enabled.split(':').any { entry ->
                    entry.equals(expected, ignoreCase = true) ||
                        (
                            entry.contains(context.packageName, ignoreCase = true) &&
                                entry.contains(
                                    "MorphOrientationService",
                                    ignoreCase = true,
                                )
                            )
                }
            } catch (_: Exception) {
                false
            }
        }

        fun reapply(context: Context) {
            if (!MorphOrientationStore.isEnabled(context)) return
            val pkg = MorphOrientationStore.lastForeground(context)
            val mode = MorphOrientationApplier.resolveModeForPackage(context, pkg)
            MorphOrientationApplier.apply(context, mode)
        }
    }
}
