package com.zibashu.morphos

import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.net.ConnectivityManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.telephony.TelephonyManager


/**
 * Best-effort shade tile state + toggle. Privileged flips open the system panel
 * instead of faking a change.
 */
object MorphQs {
    @Volatile
    private var torchOn = false

    fun snapshot(context: Context): Map<String, Any?> {
        val tiles = linkedMapOf<String, Any?>()
        tiles["wifi"] = mapOf("on" to wifiOn(context), "detail" to wifiDetail(context))
        tiles["mobile"] = mapOf("on" to mobileOn(context), "detail" to mobileDetail(context))
        tiles["bluetooth"] = mapOf("on" to bluetoothOn(context), "detail" to if (bluetoothOn(context)) "ON" else "OFF")
        tiles["airplane"] = mapOf("on" to airplaneOn(context), "detail" to "")
        tiles["flashlight"] = mapOf("on" to torchOn, "detail" to "")
        tiles["location"] = mapOf("on" to locationOn(context), "detail" to "")
        tiles["hotspot"] = mapOf("on" to false, "detail" to "")
        tiles["sound"] = mapOf("on" to !isSilent(context), "detail" to soundDetail(context))
        tiles["autoRotate"] = mapOf("on" to autoRotateOn(context), "detail" to "")
        tiles["cast"] = mapOf("on" to false, "detail" to "")
        tiles["batterySaver"] = mapOf("on" to batterySaverOn(context), "detail" to "")
        tiles["dnd"] = mapOf("on" to dndOn(context), "detail" to "")
        val out = HashMap<String, Any?>(tiles)
        out["brightness"] = brightness(context)
        out["batteryPercent"] = batteryPct(context)
        out["media"] = media(context)
        out["notifications"] = MorphNotificationStore.list()
        return out
    }

    fun toggle(context: Context, id: String): Map<String, Any?> {
        when (id) {
            "wifi" -> openPanel(context, Settings.Panel.ACTION_WIFI)
            "mobile" -> openPanel(context, Settings.Panel.ACTION_INTERNET_CONNECTIVITY)
            "bluetooth" -> openSettings(context, Settings.ACTION_BLUETOOTH_SETTINGS)
            "airplane" -> openSettings(context, Settings.ACTION_AIRPLANE_MODE_SETTINGS)
            "flashlight" -> toggleTorch(context)
            "location" -> openSettings(context, Settings.ACTION_LOCATION_SOURCE_SETTINGS)
            "hotspot" -> openSettings(context, Settings.ACTION_WIRELESS_SETTINGS)
            "sound" -> cycleRinger(context)
            "autoRotate" -> toggleAutoRotate(context)
            "cast" -> openSettings(context, "android.settings.CAST_SETTINGS")
            "batterySaver" -> openSettings(context, Settings.ACTION_BATTERY_SAVER_SETTINGS)
            "dnd" -> openSettings(context, Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            else -> {}
        }
        return snapshot(context)
    }

    fun setBrightness(context: Context, value: Double): Boolean {
        val v = (value.coerceIn(0.0, 1.0) * 255).toInt().coerceIn(1, 255)
        return try {
            if (Build.VERSION.SDK_INT >= 23 && !Settings.System.canWrite(context)) {
                openSettings(context, Settings.ACTION_MANAGE_WRITE_SETTINGS)
                return false
            }
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                v,
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    fun islandCommand(context: Context, command: String): Boolean {
        val ctrl = activeMedia(context) ?: return false
        return try {
            when {
                command == "pause" -> {
                    if (ctrl.playbackState?.state == android.media.session.PlaybackState.STATE_PLAYING) {
                        ctrl.transportControls.pause()
                    } else {
                        ctrl.transportControls.play()
                    }
                }
                command == "next" -> ctrl.transportControls.skipToNext()
                command == "previous" -> ctrl.transportControls.skipToPrevious()
                command.startsWith("seek:") -> {
                    val p = command.removePrefix("seek:").toDoubleOrNull() ?: return false
                    val dur = ctrl.metadata?.getLong(android.media.MediaMetadata.METADATA_KEY_DURATION) ?: 0L
                    if (dur > 0) ctrl.transportControls.seekTo((p * dur).toLong())
                }
                else -> return false
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    fun islandSnapshot(context: Context): Map<String, Any?> {
        val media = activeMedia(context)
        if (media != null) {
            val md = media.metadata
            val title = md?.getString(android.media.MediaMetadata.METADATA_KEY_TITLE).orEmpty()
            val artist = md?.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST).orEmpty()
            val dur = md?.getLong(android.media.MediaMetadata.METADATA_KEY_DURATION) ?: 0L
            val pos = media.playbackState?.position ?: 0L
            val playing = media.playbackState?.state ==
                android.media.session.PlaybackState.STATE_PLAYING
            return mapOf(
                "kind" to "music",
                "title" to title.ifBlank { if (playing) "Now playing" else "Music" },
                "subtitle" to artist,
                "playing" to playing,
                "progress" to if (dur > 0) pos.toDouble() / dur else 0.0,
                "expanded" to false,
                "elapsedLabel" to "",
            )
        }
        val note = MorphNotificationStore.islandHint()
        if (note != null) return note
        val musicOn = try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.isMusicActive
        } catch (_: Exception) {
            false
        }
        if (musicOn) {
            return mapOf(
                "kind" to "music",
                "title" to "Now playing",
                "subtitle" to "",
                "playing" to true,
                "progress" to 0.0,
                "expanded" to false,
                "elapsedLabel" to "",
            )
        }
        return mapOf(
            "kind" to "idle",
            "title" to "",
            "subtitle" to "",
            "playing" to false,
            "progress" to 0.0,
            "expanded" to false,
            "elapsedLabel" to "",
        )
    }

    fun runShortcut(context: Context, action: String, packageName: String): Boolean {
        return when (action) {
            "WLAN" -> openSettings(context, Settings.ACTION_WIFI_SETTINGS)
            "Bluetooth" -> openSettings(context, Settings.ACTION_BLUETOOTH_SETTINGS)
            "Display" -> openSettings(context, Settings.ACTION_DISPLAY_SETTINGS)
            "Sound" -> openSettings(context, Settings.ACTION_SOUND_SETTINGS)
            "Apps" -> openSettings(context, Settings.ACTION_APPLICATION_SETTINGS)
            "New Tab" -> openWeb(context, packageName, incognito = false)
            "Private Tab" -> openWeb(context, packageName, incognito = true)
            "Compose" -> composeMail(context, packageName)
            "Account" -> openAccount(context, packageName)
            else -> false
        }
    }

    fun openAppInfo(context: Context, packageName: String): Boolean {
        if (packageName.isBlank()) return false
        return try {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun wifiOn(context: Context): Boolean {
        return try {
            val wm = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            @Suppress("DEPRECATION")
            wm.isWifiEnabled
        } catch (_: Exception) {
            false
        }
    }

    private fun wifiDetail(context: Context): String {
        return try {
            val wm = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            @Suppress("DEPRECATION")
            wm.connectionInfo?.ssid?.trim('"').orEmpty().ifBlank { if (wifiOn(context)) "ON" else "" }
        } catch (_: Exception) {
            ""
        }
    }

    private fun mobileOn(context: Context): Boolean {
        return try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            if (Build.VERSION.SDK_INT >= 23) {
                val net = cm.activeNetwork ?: return false
                val caps = cm.getNetworkCapabilities(net) ?: return false
                caps.hasTransport(android.net.NetworkCapabilities.TRANSPORT_CELLULAR)
            } else {
                @Suppress("DEPRECATION")
                cm.activeNetworkInfo?.type == ConnectivityManager.TYPE_MOBILE
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun mobileDetail(context: Context): String {
        return try {
            val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            if (Build.VERSION.SDK_INT >= 24) {
                when (tm.dataNetworkType) {
                    TelephonyManager.NETWORK_TYPE_NR -> "5G"
                    TelephonyManager.NETWORK_TYPE_LTE -> "LTE"
                    else -> if (mobileOn(context)) "ON" else "OFF"
                }
            } else {
                if (mobileOn(context)) "ON" else "OFF"
            }
        } catch (_: Exception) {
            if (mobileOn(context)) "ON" else "OFF"
        }
    }

    private fun bluetoothOn(context: Context): Boolean {
        return try {
            val bm = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            bm.adapter?.isEnabled == true
        } catch (_: Exception) {
            false
        }
    }

    private fun airplaneOn(context: Context): Boolean {
        return try {
            Settings.Global.getInt(context.contentResolver, Settings.Global.AIRPLANE_MODE_ON, 0) == 1
        } catch (_: Exception) {
            false
        }
    }

    private fun locationOn(context: Context): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= 28) {
                val lm = context.getSystemService(Context.LOCATION_SERVICE) as android.location.LocationManager
                lm.isLocationEnabled
            } else {
                Settings.Secure.getInt(
                    context.contentResolver,
                    Settings.Secure.LOCATION_MODE,
                    Settings.Secure.LOCATION_MODE_OFF,
                ) != Settings.Secure.LOCATION_MODE_OFF
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun isSilent(context: Context): Boolean {
        return try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.ringerMode != AudioManager.RINGER_MODE_NORMAL
        } catch (_: Exception) {
            false
        }
    }

    private fun soundDetail(context: Context): String {
        return try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            when (am.ringerMode) {
                AudioManager.RINGER_MODE_SILENT -> "Mute"
                AudioManager.RINGER_MODE_VIBRATE -> "Vibrate"
                else -> "ON"
            }
        } catch (_: Exception) {
            ""
        }
    }

    private fun cycleRinger(context: Context) {
        try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.ringerMode = when (am.ringerMode) {
                AudioManager.RINGER_MODE_NORMAL -> AudioManager.RINGER_MODE_VIBRATE
                AudioManager.RINGER_MODE_VIBRATE -> AudioManager.RINGER_MODE_SILENT
                else -> AudioManager.RINGER_MODE_NORMAL
            }
        } catch (_: Exception) {
        }
    }

    private fun autoRotateOn(context: Context): Boolean {
        return try {
            Settings.System.getInt(
                context.contentResolver,
                Settings.System.ACCELEROMETER_ROTATION,
                1,
            ) == 1
        } catch (_: Exception) {
            true
        }
    }

    private fun toggleAutoRotate(context: Context) {
        try {
            if (Build.VERSION.SDK_INT >= 23 && !Settings.System.canWrite(context)) {
                openSettings(context, Settings.ACTION_MANAGE_WRITE_SETTINGS)
                return
            }
            val on = autoRotateOn(context)
            Settings.System.putInt(
                context.contentResolver,
                Settings.System.ACCELEROMETER_ROTATION,
                if (on) 0 else 1,
            )
        } catch (_: Exception) {
        }
    }

    private fun batterySaverOn(context: Context): Boolean {
        return try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isPowerSaveMode
        } catch (_: Exception) {
            false
        }
    }

    private fun dndOn(context: Context): Boolean {
        return try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            nm.currentInterruptionFilter != android.app.NotificationManager.INTERRUPTION_FILTER_ALL
        } catch (_: Exception) {
            false
        }
    }

    private fun brightness(context: Context): Double {
        return try {
            Settings.System.getInt(
                context.contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                128,
            ) / 255.0
        } catch (_: Exception) {
            0.5
        }
    }

    private fun batteryPct(context: Context): Int {
        return try {
            val intent = context.registerReceiver(
                null,
                android.content.IntentFilter(Intent.ACTION_BATTERY_CHANGED),
            )
            val level = intent?.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, 0) ?: 0
            val scale = intent?.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, 100) ?: 100
            if (scale == 0) 0 else (level * 100 / scale)
        } catch (_: Exception) {
            0
        }
    }

    private fun toggleTorch(context: Context) {
        try {
            val cm = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val id = cm.cameraIdList.firstOrNull { cam ->
                cm.getCameraCharacteristics(cam)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            } ?: return
            torchOn = !torchOn
            cm.setTorchMode(id, torchOn)
        } catch (_: Exception) {
            torchOn = false
        }
    }

    private fun activeMedia(context: Context): MediaController? {
        val msm = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
        val listener = android.content.ComponentName(context, MorphNotificationListener::class.java)
        return try {
            msm.getActiveSessions(listener).firstOrNull()
        } catch (_: Exception) {
            try {
                msm.getActiveSessions(null).firstOrNull()
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun media(context: Context): Map<String, Any?>? {
        val c = activeMedia(context) ?: return null
        val title = c.metadata?.getString(android.media.MediaMetadata.METADATA_KEY_TITLE).orEmpty()
        if (title.isBlank()) return null
        return mapOf(
            "title" to title,
            "artist" to (c.metadata?.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST) ?: ""),
            "playing" to (c.playbackState?.state == android.media.session.PlaybackState.STATE_PLAYING),
        )
    }

    private fun openPanel(context: Context, action: String) {
        try {
            context.startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (_: Exception) {
            openSettings(context, Settings.ACTION_SETTINGS)
        }
    }

    private fun openSettings(context: Context, action: String): Boolean {
        return try {
            context.startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openWeb(context: Context, packageName: String, incognito: Boolean): Boolean {
        return try {
            if (incognito) {
                val incognitoIntent = Intent("com.google.android.apps.chrome.ACTION_OPEN_NEW_INCOGNITO_TAB")
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (packageName.isNotBlank()) incognitoIntent.setPackage(packageName)
                try {
                    context.startActivity(incognitoIntent)
                    return true
                } catch (_: Exception) {
                }
            }
            val view = Intent(Intent.ACTION_VIEW, Uri.parse("https://"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (packageName.isNotBlank()) view.setPackage(packageName)
            context.startActivity(view)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun composeMail(context: Context, packageName: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (packageName.isNotBlank()) intent.setPackage(packageName)
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun openAccount(context: Context, packageName: String): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_SYNC_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            if (packageName.isNotBlank()) openAppInfo(context, packageName) else false
        }
    }
}
