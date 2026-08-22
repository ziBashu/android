package com.zibashu.keyline.ime

import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView
import com.zibashu.keyline.layout.KeyRect
import com.zibashu.keyline.layout.PopupPlacement
import com.zibashu.keyline.theme.KeylineColors

class AlternatePopup(private val context: Context) {
    private var window: PopupWindow? = null

    fun show(
        anchor: View,
        key: KeyRect,
        colors: KeylineColors,
        onPick: (String) -> Unit,
        onDismiss: () -> Unit,
    ) {
        dismiss()
        val alts = key.key.alternates
        if (alts.isEmpty()) return

        val density = context.resources.displayMetrics.density
        val pad = (8 * density).toInt()
        val cell = (40 * density).toInt()
        val row = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(pad, pad, pad, pad)
            val bg = GradientDrawable().apply {
                cornerRadius = 10 * density
                setColor(colors.popupBackground)
                setStroke((1 * density).toInt().coerceAtLeast(1), colors.keyBorder)
            }
            background = bg
            elevation = 8 * density
        }
        for (alt in alts) {
            val tv = TextView(context).apply {
                text = alt
                gravity = Gravity.CENTER
                setTextColor(colors.keyLabel)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                minWidth = cell
                minHeight = cell
                setPadding(pad, pad, pad, pad)
                contentDescription = alt
                setOnClickListener {
                    onPick(alt)
                    dismiss()
                }
            }
            row.addView(tv)
        }
        val popupW = pad * 2 + alts.size * cell
        val popupH = pad * 2 + cell
        val loc = IntArray(2)
        anchor.getLocationInWindow(loc)
        val keyInHost = KeyRect(
            key.key,
            loc[0] + key.left,
            loc[1] + key.top,
            loc[0] + key.right,
            loc[1] + key.bottom,
        )
        val dm = context.resources.displayMetrics
        val placed = PopupPlacement.place(
            key = keyInHost,
            popupWidth = popupW,
            popupHeight = popupH,
            boundsWidth = dm.widthPixels,
            boundsHeight = dm.heightPixels,
            gap = (8 * density).toInt(),
        )
        val popup = PopupWindow(row, popupW, popupH, true).apply {
            isOutsideTouchable = true
            elevation = 10 * density
            setOnDismissListener { onDismiss() }
        }
        window = popup
        val parent = anchor.rootView
        popup.showAtLocation(parent, Gravity.NO_GRAVITY, placed.x, placed.y)
    }

    fun dismiss() {
        window?.dismiss()
        window = null
    }

    val isShowing: Boolean get() = window?.isShowing == true
}
