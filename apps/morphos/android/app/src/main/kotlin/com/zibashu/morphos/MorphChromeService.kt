package com.zibashu.morphos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject

/**
 * Overlay chrome when MorphOS is not the visible home surface.
 * Stops intercepting when the matching flag is off or overlay is denied.
 */
class MorphChromeService : Service() {
    private var wm: WindowManager? = null
    private var sidebar: View? = null
    private var island: View? = null
    private var shadeHandle: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        startAsForeground()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        apply(intent)
        return START_STICKY
    }

    override fun onDestroy() {
        removeAll()
        super.onDestroy()
    }

    private fun apply(intent: Intent?) {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (intent != null) {
            if (intent.hasExtra(EXTRA_SIDEBAR)) {
                prefs.edit().putBoolean(KEY_SIDEBAR, intent.getBooleanExtra(EXTRA_SIDEBAR, true)).apply()
            }
            if (intent.hasExtra(EXTRA_SHADE)) {
                prefs.edit().putBoolean(KEY_SHADE, intent.getBooleanExtra(EXTRA_SHADE, true)).apply()
            }
            if (intent.hasExtra(EXTRA_ISLAND)) {
                prefs.edit().putBoolean(KEY_ISLAND, intent.getBooleanExtra(EXTRA_ISLAND, true)).apply()
            }
            if (intent.hasExtra(EXTRA_HOME)) {
                prefs.edit().putBoolean(KEY_HOME, intent.getBooleanExtra(EXTRA_HOME, false)).apply()
            }
            intent.getStringExtra(EXTRA_SHORTCUTS)?.let {
                prefs.edit().putString(KEY_SHORTCUTS, it).apply()
            }
        }
        val sidebarOn = prefs.getBoolean(KEY_SIDEBAR, true)
        val shadeOn = prefs.getBoolean(KEY_SHADE, true)
        val islandOn = prefs.getBoolean(KEY_ISLAND, true)
        val homeVisible = prefs.getBoolean(KEY_HOME, false)
        if (!Settings.canDrawOverlays(this) || homeVisible || (!sidebarOn && !shadeOn && !islandOn)) {
            removeAll()
            if (!sidebarOn && !shadeOn && !islandOn) {
                stopSelf()
            }
            return
        }
        if (sidebarOn) ensureSidebar() else remove(sidebar).also { sidebar = null }
        if (islandOn) ensureIsland() else remove(island).also { island = null }
        if (shadeOn) ensureShadeHandle() else remove(shadeHandle).also { shadeHandle = null }
    }

    private fun ensureSidebar() {
        if (sidebar != null) return
        val line = View(this).apply {
            setBackgroundColor(0x99FFFFFF.toInt())
            setOnClickListener { expandSidebar() }
        }
        sidebar = line
        add(line, edgeParams())
    }

    private fun expandSidebar() {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_SHORTCUTS, "[]") ?: "[]"
        val ids = try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { arr.getString(it) }
        } catch (_: Exception) {
            emptyList()
        }
        if (ids.isEmpty()) {
            bringHome("sidebar")
            return
        }
        val pkg = ids.first()
        try {
            val launch = packageManager.getLaunchIntentForPackage(pkg)
            if (launch != null) {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launch)
                return
            }
        } catch (_: Exception) {
        }
        bringHome("sidebar")
    }

    private fun ensureIsland() {
        if (island != null) return
        val pill = TextView(this).apply {
            text = "●   Now"
            setTextColor(Color.WHITE)
            textSize = 13f
            setPadding(28, 10, 28, 10)
            setBackgroundColor(0xE6000000.toInt())
            setOnClickListener { bringHome("island") }
        }
        island = pill
        val lp = baseParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
        )
        lp.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        lp.y = 8
        add(pill, lp)
    }

    private fun ensureShadeHandle() {
        if (shadeHandle != null) return
        val handle = View(this).apply {
            setBackgroundColor(Color.TRANSPARENT)
            setOnTouchListener { _, ev ->
                if (ev.action == MotionEvent.ACTION_DOWN) {
                    bringHome("shade")
                    true
                } else {
                    false
                }
            }
        }
        shadeHandle = handle
        val lp = baseParams(WindowManager.LayoutParams.MATCH_PARENT, dp(28))
        lp.gravity = Gravity.TOP
        add(handle, lp)
    }

    private fun bringHome(reason: String) {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra("morph_chrome", reason)
        startActivity(intent)
    }

    private fun edgeParams(): WindowManager.LayoutParams {
        val lp = baseParams(dp(8), dp(160))
        lp.gravity = Gravity.END or Gravity.CENTER_VERTICAL
        return lp
    }

    private fun baseParams(w: Int, h: Int): WindowManager.LayoutParams {
        val type = if (Build.VERSION.SDK_INT >= 26) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        return WindowManager.LayoutParams(
            w,
            h,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        )
    }

    private fun add(view: View, lp: WindowManager.LayoutParams) {
        try {
            wm?.addView(view, lp)
        } catch (_: Exception) {
        }
    }

    private fun remove(view: View?) {
        if (view == null) return
        try {
            wm?.removeView(view)
        } catch (_: Exception) {
        }
    }

    private fun removeAll() {
        remove(sidebar); sidebar = null
        remove(island); island = null
        remove(shadeHandle); shadeHandle = null
    }

    private fun startAsForeground() {
        val channelId = "morph_chrome"
        if (Build.VERSION.SDK_INT >= 26) {
            val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    getString(R.string.morph_chrome_channel),
                    NotificationManager.IMPORTANCE_MIN,
                ),
            )
        }
        val pending = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val n = builder
            .setContentTitle(getString(R.string.morph_chrome_title))
            .setContentText(getString(R.string.morph_chrome_text))
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentIntent(pending)
            .setOngoing(true)
            .build()
        startForeground(42, n)
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    companion object {
        const val PREFS = "morph_chrome"
        const val KEY_SIDEBAR = "sidebar"
        const val KEY_SHADE = "shade"
        const val KEY_ISLAND = "island"
        const val KEY_HOME = "home"
        const val KEY_SHORTCUTS = "shortcuts"
        const val EXTRA_SIDEBAR = "sidebar"
        const val EXTRA_SHADE = "shade"
        const val EXTRA_ISLAND = "island"
        const val EXTRA_HOME = "home"
        const val EXTRA_SHORTCUTS = "shortcuts"

        fun sync(context: Context, sidebar: Boolean, shade: Boolean, island: Boolean, shortcuts: List<String>) {
            val intent = Intent(context, MorphChromeService::class.java)
                .putExtra(EXTRA_SIDEBAR, sidebar)
                .putExtra(EXTRA_SHADE, shade)
                .putExtra(EXTRA_ISLAND, island)
                .putExtra(EXTRA_SHORTCUTS, JSONArray(shortcuts).toString())
            ContextCompatStart.start(context, intent)
        }

        fun setHomeVisible(context: Context, visible: Boolean) {
            val intent = Intent(context, MorphChromeService::class.java)
                .putExtra(EXTRA_HOME, visible)
            ContextCompatStart.start(context, intent)
        }
    }
}

private object ContextCompatStart {
    fun start(context: Context, intent: Intent) {
        try {
            if (Build.VERSION.SDK_INT >= 26) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        } catch (_: Exception) {
        }
    }
}
