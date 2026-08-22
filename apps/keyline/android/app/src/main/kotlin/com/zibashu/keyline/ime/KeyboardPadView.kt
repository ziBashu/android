package com.zibashu.keyline.ime

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.MotionEvent
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import com.zibashu.keyline.input.ShiftMode
import com.zibashu.keyline.layout.KeyRect
import com.zibashu.keyline.layout.KeyType
import com.zibashu.keyline.layout.KeylineMetrics
import com.zibashu.keyline.layout.LayoutEngine
import com.zibashu.keyline.theme.KeylineColors

class KeyboardPadView(context: Context) : View(context) {
    var listener: Listener? = null
    var colors: KeylineColors? = null
    var gapPx: Int = 8
    var cornerPx: Float = 8f
    var shiftMode: ShiftMode = ShiftMode.OFF
    var layoutId: String = ""
        private set

    private var rects: List<KeyRect> = emptyList()
    private var pressedId: String? = null
    private val handler = Handler(Looper.getMainLooper())
    private val tmpRect = RectF()

    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = 1f
    }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.NORMAL)
    }

    private val longPress = Runnable {
        val id = pressedId ?: return@Runnable
        val rect = rects.find { it.key.id == id } ?: return@Runnable
        if (rect.key.alternates.isNotEmpty()) {
            listener?.onLongPress(rect)
        } else if (rect.key.type == KeyType.BACKSPACE) {
            startBackspaceRepeat()
        }
    }

    private val backspaceRepeat = object : Runnable {
        override fun run() {
            listener?.onBackspaceRepeat()
            handler.postDelayed(this, KeylineMetrics.BACKSPACE_REPEAT_MS)
        }
    }

    interface Listener {
        fun onKeyUp(rect: KeyRect, windowX: Int, windowY: Int)
        fun onLongPress(rect: KeyRect)
        fun onFingerMove(windowX: Int, windowY: Int)
        fun onBackspaceRepeat()
        fun onPressFeedback()
        fun onCancel()
    }

    fun bindLayout(layout: com.zibashu.keyline.layout.KeyboardLayout) {
        layoutId = layout.id
        relayout(layout)
        invalidate()
    }

    fun setShift(mode: ShiftMode) {
        if (shiftMode != mode) {
            shiftMode = mode
            invalidate()
        }
    }

    fun cancelPress() {
        pressedId = null
        handler.removeCallbacks(longPress)
        handler.removeCallbacks(backspaceRepeat)
        invalidate()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        val current = listenerLayout()
        if (current != null) relayout(current)
    }

    private fun listenerLayout() = (listener as? LayoutSource)?.currentLayout()

    interface LayoutSource {
        fun currentLayout(): com.zibashu.keyline.layout.KeyboardLayout?
    }

    private fun relayout(layout: com.zibashu.keyline.layout.KeyboardLayout) {
        if (width <= 0 || height <= 0) return
        rects = LayoutEngine.measure(layout, width, height, gapPx)
    }

    override fun onDraw(canvas: Canvas) {
        val palette = colors ?: return
        canvas.drawColor(palette.keyboardBackground)
        val labelSize = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_SP,
            16f,
            resources.displayMetrics,
        )
        textPaint.textSize = labelSize
        textPaint.color = palette.keyLabel
        strokePaint.color = palette.keyBorder
        val fm = textPaint.fontMetrics
        val textOffset = (fm.ascent + fm.descent) / 2f

        for (rect in rects) {
            val special = rect.key.isSpecial
            val pressed = rect.key.id == pressedId
            fillPaint.color = when {
                rect.key.type == KeyType.SHIFT && shiftMode == ShiftMode.CAPS_LOCK ->
                    palette.capsLock
                rect.key.type == KeyType.SHIFT && shiftMode == ShiftMode.SHIFTED ->
                    palette.shiftArmed
                special && pressed -> palette.keySpecialFillPressed
                special -> palette.keySpecialFill
                pressed -> palette.keyFillPressed
                else -> palette.keyFill
            }
            tmpRect.set(
                rect.left.toFloat(),
                rect.top.toFloat(),
                rect.right.toFloat(),
                rect.bottom.toFloat(),
            )
            canvas.drawRoundRect(tmpRect, cornerPx, cornerPx, fillPaint)
            canvas.drawRoundRect(tmpRect, cornerPx, cornerPx, strokePaint)

            val label = displayLabel(rect)
            if (label.isNotEmpty()) {
                val cx = (rect.left + rect.right) / 2f
                val cy = (rect.top + rect.bottom) / 2f - textOffset
                canvas.drawText(label, cx, cy, textPaint)
            }
        }
    }

    private fun displayLabel(rect: KeyRect): String {
        val key = rect.key
        if (key.type == KeyType.SHIFT) {
            return if (shiftMode == ShiftMode.CAPS_LOCK) "⇪" else "⇧"
        }
        if (key.type == KeyType.SPACE) return ""
        if (key.type == KeyType.CHARACTER && key.output.length == 1 && key.output[0].isLetter()) {
            return key.label
        }
        return key.label
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                val hit = hit(event.x.toInt(), event.y.toInt()) ?: return true
                pressedId = hit.key.id
                handler.removeCallbacks(longPress)
                handler.removeCallbacks(backspaceRepeat)
                handler.postDelayed(longPress, KeylineMetrics.LONG_PRESS_MS)
                listener?.onPressFeedback()
                announceForAccessibility(hit.key.contentDescription)
                invalidate()
            }
            MotionEvent.ACTION_MOVE -> {
                val wx = windowX(event.x)
                val wy = windowY(event.y)
                listener?.onFingerMove(wx, wy)
                val hit = hit(event.x.toInt(), event.y.toInt())
                if (hit?.key?.id != pressedId) {
                    handler.removeCallbacks(longPress)
                }
            }
            MotionEvent.ACTION_UP -> {
                val id = pressedId
                handler.removeCallbacks(longPress)
                handler.removeCallbacks(backspaceRepeat)
                pressedId = null
                invalidate()
                val hit = id?.let { want -> rects.find { it.key.id == want } }
                if (hit != null) {
                    listener?.onKeyUp(hit, windowX(event.x), windowY(event.y))
                }
            }
            MotionEvent.ACTION_CANCEL -> {
                cancelPress()
                listener?.onCancel()
            }
        }
        return true
    }

    private fun startBackspaceRepeat() {
        handler.removeCallbacks(backspaceRepeat)
        listener?.onBackspaceRepeat()
        handler.postDelayed(backspaceRepeat, KeylineMetrics.BACKSPACE_REPEAT_MS)
    }

    private fun windowX(localX: Float): Int {
        val loc = IntArray(2)
        getLocationInWindow(loc)
        return loc[0] + localX.toInt()
    }

    private fun windowY(localY: Float): Int {
        val loc = IntArray(2)
        getLocationInWindow(loc)
        return loc[1] + localY.toInt()
    }

    fun hit(x: Int, y: Int): KeyRect? = rects.find { it.contains(x, y) }

    fun keyRects(): List<KeyRect> = rects

    override fun onInitializeAccessibilityNodeInfo(info: AccessibilityNodeInfo) {
        super.onInitializeAccessibilityNodeInfo(info)
        info.className = "android.widget.KeyboardView"
        info.contentDescription = "KEYLINE keyboard"
        info.isClickable = true
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        handler.removeCallbacksAndMessages(null)
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(
            MeasureSpec.getSize(widthMeasureSpec),
            MeasureSpec.getSize(heightMeasureSpec),
        )
    }
}
