package com.zibashu.morphos

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * MorphOS host activity — LauncherOS-style home root.
 *
 * HOME intent lands here; Back at root moves task to background (does not
 * "exit app"); Flutter is notified to pop to Morph home on Home re-entry.
 *
 * Texture + opaque avoids pure-black SurfaceView composite failures on some
 * API 36–37 emulators.
 */
class MainActivity : FlutterActivity() {
    private var bridge: MorphSystemBridge? = null
    private var launcherEvents: EventChannel.EventSink? = null

    override fun getRenderMode(): RenderMode = RenderMode.texture

    override fun getTransparencyMode(): TransparencyMode = TransparencyMode.opaque

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Always treat the latest intent as current (HOME re-entry).
        intent?.let { setIntent(it) }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = MorphSystemBridge(applicationContext, this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler(bridge)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MorphBatteryStream.CHANNEL,
        ).setStreamHandler(MorphBatteryStream(applicationContext))

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                launcherEvents = events
                // Deliver current intent category so first frame can align.
                emitLauncherEvent(intent)
            }

            override fun onCancel(arguments: Any?) {
                launcherEvents = null
            }
        })
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Home button while MorphOS is already the task → pop Flutter to root.
        emitLauncherEvent(intent)
    }

    override fun onResume() {
        super.onResume()
        // When returning via HOME as default launcher, force home surface.
        if (isHomeIntent(intent)) {
            emitLauncherEvent(intent)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Never finish the home root activity — behave like a launcher.
        // Flutter PopScope handles in-app routes; at root it calls moveTaskToBack.
        // If Flutter does not consume, still stay alive.
        if (!moveTaskToBack(true)) {
            @Suppress("DEPRECATION")
            super.onBackPressed()
        }
    }

    private fun emitLauncherEvent(intent: Intent?) {
        val sink = launcherEvents ?: return
        val type = when {
            isHomeIntent(intent) -> "home"
            isLauncherIntent(intent) -> "launcher"
            else -> "resume"
        }
        try {
            sink.success(
                mapOf(
                    "type" to type,
                    "action" to (intent?.action ?: ""),
                    "categories" to (intent?.categories?.toList() ?: emptyList<String>()),
                    "isDefaultHome" to MorphPlatform.isDefaultHome(applicationContext),
                ),
            )
        } catch (_: Exception) {
            // EventSink may be closed during teardown.
        }
    }

    companion object {
        private const val METHOD_CHANNEL = "com.zibashu.morphos/system"
        private const val EVENT_CHANNEL = "com.zibashu.morphos/launcher"

        fun isHomeIntent(intent: Intent?): Boolean {
            if (intent == null) return false
            val cats = intent.categories ?: return false
            return Intent.ACTION_MAIN == intent.action &&
                cats.contains(Intent.CATEGORY_HOME)
        }

        fun isLauncherIntent(intent: Intent?): Boolean {
            if (intent == null) return false
            val cats = intent.categories ?: return false
            return Intent.ACTION_MAIN == intent.action &&
                cats.contains(Intent.CATEGORY_LAUNCHER)
        }
    }
}
