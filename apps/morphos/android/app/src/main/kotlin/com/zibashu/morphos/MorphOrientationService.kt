package com.zibashu.morphos

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

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
        MorphOrientationApplier.apply(this, mode)
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

        fun reapply(context: android.content.Context) {
            if (!MorphOrientationStore.isEnabled(context)) return
            val pkg = MorphOrientationStore.lastForeground(context)
            val mode = MorphOrientationApplier.resolveModeForPackage(context, pkg)
            MorphOrientationApplier.apply(context, mode)
        }
    }
}
