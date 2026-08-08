package com.zibashu.morphos

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MorphOS host activity.
 *
 * Texture + opaque avoids pure-black SurfaceView composite failures on some
 * API 36–37 emulators, while still receiving input.
 */
class MainActivity : FlutterActivity() {
    private var bridge: MorphSystemBridge? = null

    override fun getRenderMode(): RenderMode = RenderMode.texture

    override fun getTransparencyMode(): TransparencyMode = TransparencyMode.opaque

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = MorphSystemBridge(applicationContext, this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler(bridge)
    }

    companion object {
        private const val CHANNEL = "com.zibashu.morphos/system"
    }
}
