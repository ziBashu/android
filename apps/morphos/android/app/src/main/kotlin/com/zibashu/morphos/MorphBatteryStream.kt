package com.zibashu.morphos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import io.flutter.plugin.common.EventChannel

/**
 * Pushes every [Intent.ACTION_BATTERY_CHANGED] extras map to Flutter.
 * The sticky broadcast is delivered immediately on listen.
 */
class MorphBatteryStream(
    private val context: Context,
) : EventChannel.StreamHandler {

    private var receiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events == null) return
        val rec = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                if (intent == null) return
                if (intent.action != Intent.ACTION_BATTERY_CHANGED) return
                try {
                    events.success(extrasFrom(intent))
                } catch (_: Exception) {
                    // Sink may be closed during teardown.
                }
            }
        }
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val sticky = try {
            if (Build.VERSION.SDK_INT >= 33) {
                context.registerReceiver(rec, filter, Context.RECEIVER_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                context.registerReceiver(rec, filter)
            }
        } catch (_: Exception) {
            null
        }
        receiver = rec
        if (sticky != null) {
            try {
                events.success(extrasFrom(sticky))
            } catch (_: Exception) {
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        val rec = receiver ?: return
        receiver = null
        try {
            context.unregisterReceiver(rec)
        } catch (_: Exception) {
        }
    }

    companion object {
        const val CHANNEL = "com.zibashu.morphos/battery"

        fun extrasFrom(intent: Intent): Map<String, Any?> {
            return mapOf(
                "level" to intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1),
                "scale" to intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100),
                "status" to intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1),
                "plugged" to intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0),
                "temperature" to intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0),
                "health" to intent.getIntExtra(BatteryManager.EXTRA_HEALTH, 1),
                "voltage" to intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0),
                "technology" to (intent.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY) ?: ""),
            )
        }
    }
}
