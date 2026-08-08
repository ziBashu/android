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
        if (!MorphOrientationStore.isEnabled(context)) {
            Log.i(TAG, "Boot: system morph disabled — skip")
            return
        }
        MorphOrientationService.reapply(context)
        Log.i(TAG, "Boot: reapplied morph orientation")
    }

    companion object {
        private const val TAG = "MorphBootReceiver"
    }
}
