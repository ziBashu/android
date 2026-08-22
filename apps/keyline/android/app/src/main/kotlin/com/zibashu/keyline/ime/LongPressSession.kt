package com.zibashu.keyline.ime

data class PopupCell(
    val token: String,
    val left: Int,
    val top: Int,
    val right: Int,
    val bottom: Int,
) {
    fun contains(x: Int, y: Int): Boolean =
        x >= left && x < right && y >= top && y < bottom
}

/**
 * One-finger long-press state. Once the alternate popup is shown, [up] never
 * commits the base key — only a highlighted/picked alternate, or nothing.
 */
class LongPressSession {
    var isOpen: Boolean = false
        private set
    var highlighted: String? = null
        private set

    private var cells: List<PopupCell> = emptyList()
    private var popupWasShown: Boolean = false
    private var picked: String? = null

    fun start(cells: List<PopupCell>) {
        this.cells = cells
        isOpen = cells.isNotEmpty()
        popupWasShown = isOpen
        highlighted = null
        picked = null
    }

    fun move(x: Int, y: Int) {
        if (!isOpen) return
        highlighted = cells.firstOrNull { it.contains(x, y) }?.token
    }

    fun pick(token: String) {
        if (!popupWasShown) return
        picked = token
        highlighted = token
        isOpen = false
    }

    fun up(): UpResult {
        val token = picked ?: highlighted
        val shown = popupWasShown
        reset()
        return when {
            token != null -> UpResult.Alternate(token)
            shown -> UpResult.Nothing
            else -> UpResult.CommitBase
        }
    }

    fun cancel() {
        picked = null
        highlighted = null
        isOpen = false
        // Keep popupWasShown so a following up() does not emit the base letter.
    }

    private fun reset() {
        isOpen = false
        highlighted = null
        cells = emptyList()
        popupWasShown = false
        picked = null
    }

    sealed class UpResult {
        data object CommitBase : UpResult()
        data object Nothing : UpResult()
        data class Alternate(val token: String) : UpResult()
    }
}

object PopupCells {
    fun row(
        tokens: List<String>,
        originX: Int,
        originY: Int,
        pad: Int,
        cell: Int,
    ): List<PopupCell> = tokens.mapIndexed { index, token ->
        val left = originX + pad + index * cell
        PopupCell(
            token = token,
            left = left,
            top = originY + pad,
            right = left + cell,
            bottom = originY + pad + cell,
        )
    }
}
