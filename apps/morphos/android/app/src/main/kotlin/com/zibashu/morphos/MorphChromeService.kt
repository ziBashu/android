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
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONArray

/**
 * Overlay chrome when MorphOS is not the visible home surface.
 * Sidebar handle stays on the screen rim and works over other apps.
 */
class MorphChromeService : Service() {
    private var wm: WindowManager? = null
    private var sidebar: View? = null
    private var island: TextView? = null
    private var shadeHandle: View? = null
    private var expanded: LinearLayout? = null
    private val handler = Handler(Looper.getMainLooper())
    private val islandTick = object : Runnable {
        override fun run() {
            // Do not draw an overlay island. The 1.5s tick used to re-add a
            // TOP-CENTER "Now playing" pill on top of the OEM Magic Capsule.
            remove(island).also { island = null }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        startAsForeground()
        handler.post(islandTick)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        apply(intent)
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(islandTick)
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
            intent.getStringExtra(EXTRA_RIM)?.let {
                prefs.edit().putString(KEY_RIM, it).apply()
            }
            if (intent.hasExtra(EXTRA_ALONG)) {
                prefs.edit().putFloat(KEY_ALONG, intent.getDoubleExtra(EXTRA_ALONG, 0.42).toFloat()).apply()
            }
        }
        val sidebarOn = prefs.getBoolean(KEY_SIDEBAR, true)
        val shadeOn = prefs.getBoolean(KEY_SHADE, true)
        val islandOn = prefs.getBoolean(KEY_ISLAND, true)
        val homeVisible = prefs.getBoolean(KEY_HOME, false)
        if (!Settings.canDrawOverlays(this) || (!sidebarOn && !shadeOn && !islandOn)) {
            removeAll()
            if (!sidebarOn && !shadeOn && !islandOn) stopSelf()
            return
        }
        // Flutter draws chrome on MorphOS home; overlay is for other apps.
        if (homeVisible) {
            removeAll()
            return
        }
        if (sidebarOn) ensureSidebar() else remove(sidebar).also { sidebar = null }
        // Never draw an overlay island. A TOP-CENTER pill sits on the OEM
        // Magic Capsule (Honor / system island) and shows a second "Now playing".
        remove(island).also { island = null }
        // Shade is home-only. A full-width TYPE_APPLICATION_OVERLAY at y=0
        // would steal the OEM status-bar swipe. Do not add a MATCH_PARENT
        // Gravity.TOP handle.
        remove(shadeHandle).also { shadeHandle = null }
    }

    private fun ensureSidebar() {
        if (sidebar != null) {
            updateSidebarLp()
            return
        }
        val line = View(this).apply {
            setBackgroundColor(0xB3FFFFFF.toInt())
            setOnTouchListener(HandleTouch())
        }
        sidebar = line
        add(line, handleLp())
    }

    private inner class HandleTouch : View.OnTouchListener {
        private var downX = 0f
        private var downY = 0f
        private var moved = false

        override fun onTouch(v: View, ev: MotionEvent): Boolean {
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = ev.rawX
                    downY = ev.rawY
                    moved = false
                    return true
                }
                MotionEvent.ACTION_MOVE -> {
                    if (kotlin.math.abs(ev.rawX - downX) > 12 || kotlin.math.abs(ev.rawY - downY) > 12) {
                        moved = true
                        persistPoint(ev.rawX, ev.rawY)
                        updateSidebarLp()
                    }
                    return true
                }
                MotionEvent.ACTION_UP -> {
                    val dx = ev.rawX - downX
                    val dy = ev.rawY - downY
                    if (!moved || inwardSwipe(dx, dy)) toggleExpanded()
                    return true
                }
            }
            return false
        }
    }

    private fun persistPoint(x: Float, y: Float) {
        val dm = resources.displayMetrics
        val w = dm.widthPixels.toFloat()
        val h = dm.heightPixels.toFloat()
        val dl = x
        val dr = w - x
        val dt = y
        val db = h - y
        val m = minOf(dl, dr, dt, db)
        val rim = when (m) {
            dl -> "left"
            dr -> "right"
            dt -> "top"
            else -> "bottom"
        }
        val along = when (rim) {
            "left", "right" -> (y / h).coerceIn(0.08f, 0.92f)
            else -> (x / w).coerceIn(0.08f, 0.92f)
        }
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_RIM, rim)
            .putFloat(KEY_ALONG, along)
            .apply()
    }

    private fun inwardSwipe(dx: Float, dy: Float): Boolean {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val rim = prefs.getString(KEY_RIM, "right") ?: "right"
        val minInward = dp(20).toFloat()
        return when (rim) {
            "left" -> dx >= minInward
            "right" -> dx <= -minInward
            "top" -> dy >= minInward
            else -> dy <= -minInward
        }
    }

    private fun handleLp(): WindowManager.LayoutParams {
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val rim = prefs.getString(KEY_RIM, "right") ?: "right"
        val along = prefs.getFloat(KEY_ALONG, 0.42f)
        val vertical = rim == "left" || rim == "right"
        val lp = baseParams(
            if (vertical) dp(SIDEBAR_HIT_W_DP) else dp(SIDEBAR_HIT_H_DP),
            if (vertical) dp(SIDEBAR_HIT_H_DP) else dp(SIDEBAR_HIT_W_DP),
        )
        lp.gravity = when (rim) {
            "left" -> Gravity.START or Gravity.TOP
            "right" -> Gravity.END or Gravity.TOP
            "top" -> Gravity.TOP or Gravity.START
            else -> Gravity.BOTTOM or Gravity.START
        }
        val dm = resources.displayMetrics
        if (vertical) {
            lp.y = (along * (dm.heightPixels - dp(SIDEBAR_HIT_H_DP))).toInt()
            lp.x = 0
        } else {
            lp.x = (along * (dm.widthPixels - dp(SIDEBAR_HIT_H_DP))).toInt()
            lp.y = if (rim == "top") dp(STATUS_BAR_BAND_DP) else 0
        }
        return lp
    }

    private fun updateSidebarLp() {
        val v = sidebar ?: return
        try {
            wm?.updateViewLayout(v, handleLp())
        } catch (_: Exception) {
        }
    }

    private fun toggleExpanded() {
        if (expanded != null) {
            remove(expanded)
            expanded = null
            return
        }
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_SHORTCUTS, "[]") ?: "[]"
        val ids = try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { arr.getString(it) }
        } catch (_: Exception) {
            emptyList()
        }
        val col = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xE61A1A1A.toInt())
            setPadding(dp(8), dp(10), dp(8), dp(10))
        }
        val pm = packageManager
        for (id in ids.take(10)) {
            val launch = pm.getLaunchIntentForPackage(id) ?: continue
            val iv = ImageView(this)
            try {
                iv.setImageDrawable(pm.getApplicationIcon(id))
            } catch (_: Exception) {
            }
            val lp = LinearLayout.LayoutParams(dp(40), dp(40))
            lp.bottomMargin = dp(8)
            iv.setOnClickListener {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launch)
                toggleExpanded()
            }
            col.addView(iv, lp)
        }
        if (col.childCount == 0) {
            bringHome("sidebar")
            return
        }
        expanded = col
        val rim = prefs.getString(KEY_RIM, "right") ?: "right"
        val along = prefs.getFloat(KEY_ALONG, 0.42f)
        val lp = baseParams(dp(56), WindowManager.LayoutParams.WRAP_CONTENT)
        lp.gravity = when (rim) {
            "left" -> Gravity.START or Gravity.TOP
            else -> Gravity.END or Gravity.TOP
        }
        lp.y = (along * resources.displayMetrics.heightPixels).toInt()
        lp.x = dp(10)
        add(col, lp)
    }

    private fun refreshIsland() {
        remove(island).also { island = null }
    }

    private fun bringHome(reason: String) {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra("morph_chrome", reason)
        startActivity(intent)
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
        remove(expanded); expanded = null
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
        const val SIDEBAR_HIT_W_DP = 32
        const val SIDEBAR_HIT_H_DP = 128
        const val STATUS_BAR_BAND_DP = 32
        const val ISLAND_TOP_INSET_DP = 56
        const val PREFS = "morph_chrome"
        const val KEY_SIDEBAR = "sidebar"
        const val KEY_SHADE = "shade"
        const val KEY_ISLAND = "island"
        const val KEY_HOME = "home"
        const val KEY_SHORTCUTS = "shortcuts"
        const val KEY_RIM = "rim"
        const val KEY_ALONG = "along"
        const val EXTRA_SIDEBAR = "sidebar"
        const val EXTRA_SHADE = "shade"
        const val EXTRA_ISLAND = "island"
        const val EXTRA_HOME = "home"
        const val EXTRA_SHORTCUTS = "shortcuts"
        const val EXTRA_RIM = "rim"
        const val EXTRA_ALONG = "along"

        fun sync(
            context: Context,
            sidebar: Boolean,
            shade: Boolean,
            island: Boolean,
            shortcuts: List<String>,
            rim: String = "right",
            along: Double = 0.42,
        ) {
            val intent = Intent(context, MorphChromeService::class.java)
                .putExtra(EXTRA_SIDEBAR, sidebar)
                .putExtra(EXTRA_SHADE, shade)
                .putExtra(EXTRA_ISLAND, island)
                .putExtra(EXTRA_SHORTCUTS, JSONArray(shortcuts).toString())
                .putExtra(EXTRA_RIM, rim)
                .putExtra(EXTRA_ALONG, along)
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
