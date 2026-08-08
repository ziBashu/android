package com.zibashu.morphos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Phase 6 — restore system morph orientation after reboot.
 */
class MorphBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        // Only reapply forced rotation when user enabled system morph.
        // No network, no package scan — local prefs only.
        if (!MorphOrientationStore.isEnabled(context)) {
            Log.i(TAG, "Boot: system morph disabled — skip")
            return
        }
        try {
            MorphOrientationService.reapply(context)
            Log.i(TAG, "Boot: reapplied morph orientation")
        } catch (e: Exception) {
            Log.w(TAG, "Boot reapply failed: ${e.message}")
        }
    }

    companion object {
        private const val TAG = "MorphBootReceiver"
    }
}
