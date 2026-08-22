package com.zibashu.keyline.layout

data class PopupBox(
    val x: Int,
    val y: Int,
    val width: Int,
    val height: Int,
)

/**
 * Places a compact alternate-character popup near a key and clamps it so it
 * stays inside [bounds]. Prefers sitting above the key; flips below if needed.
 */
object PopupPlacement {
    fun place(
        key: KeyRect,
        popupWidth: Int,
        popupHeight: Int,
        boundsWidth: Int,
        boundsHeight: Int,
        gap: Int = 8,
        boundsLeft: Int = 0,
        boundsTop: Int = 0,
    ): PopupBox {
        val boundsRight = boundsLeft + boundsWidth
        val boundsBottom = boundsTop + boundsHeight
        var x = key.left + (key.width - popupWidth) / 2
        var y = key.top - popupHeight - gap
        if (y < boundsTop) {
            y = key.bottom + gap
        }
        if (y + popupHeight > boundsBottom) {
            y = boundsBottom - popupHeight
        }
        if (x < boundsLeft) x = boundsLeft
        if (x + popupWidth > boundsRight) x = boundsRight - popupWidth
        y = y.coerceAtLeast(boundsTop)
        x = x.coerceAtLeast(boundsLeft)
        return PopupBox(x, y, popupWidth, popupHeight)
    }
}
