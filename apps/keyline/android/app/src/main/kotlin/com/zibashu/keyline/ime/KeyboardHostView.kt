package com.zibashu.keyline.ime

import android.content.Context
import android.graphics.Typeface
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.media.AudioManager
import android.util.TypedValue
import android.view.Gravity
import android.view.WindowInsets
import android.widget.LinearLayout
import android.widget.TextView
import com.zibashu.keyline.input.InputController
import com.zibashu.keyline.layout.KeyRect
import com.zibashu.keyline.layout.KeyType
import com.zibashu.keyline.layout.KeylineMetrics
import com.zibashu.keyline.layout.KeyboardLayout
import com.zibashu.keyline.settings.KeylineSettingsSnapshot
import com.zibashu.keyline.theme.KeylineColors
import com.zibashu.keyline.theme.KeylinePalette

class KeyboardHostView(context: Context) : LinearLayout(context),
    KeyboardPadView.Listener,
    KeyboardPadView.LayoutSource {

    var controller: InputController? = null
    var settings: KeylineSettingsSnapshot = KeylineSettingsSnapshot.defaults
    var colors: KeylineColors = KeylinePalette.Light
        private set

    private val suggestionBar: LinearLayout
    private val pad: KeyboardPadView
    private val popup = AlternatePopup(context)
    private var longPressConsumed = false
    private val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    init {
        orientation = VERTICAL
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_YES
        contentDescription = "KEYLINE keyboard"

        suggestionBar = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        pad = KeyboardPadView(context).apply {
            listener = this@KeyboardHostView
        }
        addView(suggestionBar, LayoutParams(LayoutParams.MATCH_PARENT, 0))
        addView(pad, LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f))
        setOnApplyWindowInsetsListener { _, insets ->
            val bottom = if (Build.VERSION.SDK_INT >= 30) {
                insets.getInsets(WindowInsets.Type.navigationBars()).bottom
            } else {
                @Suppress("DEPRECATION")
                insets.systemWindowInsetBottom
            }
            setPadding(0, 0, 0, bottom)
            insets
        }
    }

    fun applyChrome(snapshot: KeylineSettingsSnapshot, systemDark: Boolean) {
        settings = snapshot
        colors = KeylinePalette.resolve(snapshot.theme, systemDark)
        setBackgroundColor(colors.keyboardBackground)
        val density = resources.displayMetrics.density
        pad.colors = colors
        pad.gapPx = (KeylineMetrics.gapDp(snapshot.spacing) * density).toInt().coerceAtLeast(2)
        pad.cornerPx = KeylineMetrics.cornerDp(snapshot.spacing) * density
        minimumWidth = resources.displayMetrics.widthPixels
        minimumHeight = keyboardHeightPx()
        requestLayout()
        bindController(controller)
    }

    fun bindController(next: InputController?) {
        controller = next
        val c = next ?: return
        c.onStateChanged = { post { refresh() } }
        refresh()
    }

    fun keyboardHeightPx(): Int {
        val density = resources.displayMetrics.density
        val kb = (KeylineMetrics.keyboardHeightDp(settings.height) * density).toInt()
        val sug = if (showSuggestions()) {
            (KeylineMetrics.SUGGESTION_ROW_DP * density).toInt()
        } else {
            0
        }
        return kb + sug + paddingBottom
    }

    private fun showSuggestions(): Boolean {
        val c = controller ?: return settings.suggestions
        return !c.suggestionsSuppressed()
    }

    private fun refresh() {
        val c = controller ?: return
        pad.setShift(c.shiftMode)
        val layout = c.currentLayout()
        if (pad.layoutId != layout.id || pad.keyRects().isEmpty()) {
            pad.bindLayout(layout)
        } else {
            pad.invalidate()
        }
        rebuildSuggestions(c.suggestions)
        requestLayout()
        invalidate()
    }

    private fun rebuildSuggestions(items: List<String>) {
        suggestionBar.removeAllViews()
        val visible = showSuggestions()
        suggestionBar.visibility = if (visible) VISIBLE else GONE
        suggestionBar.setBackgroundColor(colors.suggestionBackground)
        if (!visible) return
        val density = resources.displayMetrics.density
        val padH = (8 * density).toInt()
        suggestionBar.setPadding(padH, 0, padH, 0)
        for (word in items.take(3)) {
            val tv = TextView(context).apply {
                text = word
                setTextColor(colors.suggestionText)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
                gravity = Gravity.CENTER
                setPadding((16 * density).toInt(), 0, (16 * density).toInt(), 0)
                contentDescription = word
                setOnClickListener { controller?.pickSuggestion(word) }
            }
            suggestionBar.addView(tv, LayoutParams(0, LayoutParams.MATCH_PARENT, 1f))
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val specWidth = MeasureSpec.getSize(widthMeasureSpec)
        val width = if (specWidth > 0) specWidth else resources.displayMetrics.widthPixels
        val total = keyboardHeightPx()
        val sugH = if (showSuggestions()) {
            (KeylineMetrics.SUGGESTION_ROW_DP * resources.displayMetrics.density).toInt()
        } else {
            0
        }
        suggestionBar.measure(
            MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(sugH, MeasureSpec.EXACTLY),
        )
        pad.measure(
            MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(total - sugH, MeasureSpec.EXACTLY),
        )
        setMeasuredDimension(width, total)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val sugH = suggestionBar.measuredHeight
        suggestionBar.layout(0, 0, r - l, sugH)
        pad.layout(0, sugH, r - l, (b - t) - paddingBottom)
    }

    override fun currentLayout(): KeyboardLayout? = controller?.currentLayout()

    override fun onKeyUp(rect: KeyRect) {
        if (longPressConsumed) {
            val stillOpen = popup.isShowing
            popup.dismiss()
            longPressConsumed = false
            if (stillOpen) {
                controller?.onKey(rect.key)
            }
            return
        }
        controller?.onKey(rect.key)
        if (rect.key.type != KeyType.SHIFT) {
            pad.bindLayout(controller?.currentLayout() ?: return)
        }
    }

    override fun onLongPress(rect: KeyRect) {
        longPressConsumed = true
        popup.show(
            anchor = pad,
            key = rect,
            colors = colors,
            onPick = { token ->
                longPressConsumed = true
                controller?.pickAlternate(token)
                pad.cancelPress()
            },
            onDismiss = {
                pad.cancelPress()
            },
        )
    }

    override fun onBackspaceRepeat() {
        val key = controller?.currentLayout()?.findKey("backspace") ?: return
        controller?.onKey(key)
    }

    override fun onPressFeedback() {
        if (settings.sound) {
            audio.playSoundEffect(AudioManager.FX_KEYPRESS_STANDARD)
        }
        if (settings.vibration) vibrateKey()
    }

    override fun onCancel() {
        popup.dismiss()
        longPressConsumed = false
    }

    fun dismissPopup() {
        popup.dismiss()
        longPressConsumed = false
        pad.cancelPress()
    }

    private fun vibrateKey() {
        val vibrator = if (Build.VERSION.SDK_INT >= 31) {
            val mgr = context.getSystemService(VibratorManager::class.java)
            mgr?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        } ?: return
        if (Build.VERSION.SDK_INT >= 26) {
            vibrator.vibrate(VibrationEffect.createOneShot(16, 36))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(16)
        }
    }
}
