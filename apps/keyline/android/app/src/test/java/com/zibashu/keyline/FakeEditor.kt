package com.zibashu.keyline

import com.zibashu.keyline.input.InputKinds
import com.zibashu.keyline.input.KeylineEditor
import kotlin.math.max
import kotlin.math.min

/**
 * Minimal InputConnection stand-in. Exercises the shipped InputController;
 * it is not a second implementation of keyboard logic.
 */
class FakeEditor(
    override var inputType: Int = InputKinds.TYPE_CLASS_TEXT or InputKinds.TYPE_TEXT_FLAG_CAP_SENTENCES,
) : KeylineEditor {
    private val buffer = StringBuilder()
    var cursor: Int = 0
        private set
    var selStart: Int = 0
        private set
    var selEnd: Int = 0
        private set
    var composing: String? = null
        private set
    var enterCount: Int = 0
        private set

    val text: String get() = buffer.toString()

    fun setText(value: String, cursorAt: Int = value.length) {
        buffer.setLength(0)
        buffer.append(value)
        cursor = cursorAt.coerceIn(0, buffer.length)
        selStart = cursor
        selEnd = cursor
        composing = null
    }

    fun select(start: Int, end: Int) {
        selStart = start.coerceIn(0, buffer.length)
        selEnd = end.coerceIn(0, buffer.length)
        cursor = selEnd
        composing = null
    }

    override fun getTextBeforeCursor(n: Int): String {
        val start = (cursor - n).coerceAtLeast(0)
        return buffer.substring(start, cursor)
    }

    override fun getTextAfterCursor(n: Int): String {
        val end = (cursor + n).coerceAtMost(buffer.length)
        return buffer.substring(cursor, end)
    }

    override fun getSelectedText(): String {
        if (selStart == selEnd) return ""
        val a = min(selStart, selEnd)
        val b = max(selStart, selEnd)
        return buffer.substring(a, b)
    }

    override fun commitText(text: String) {
        replaceComposingOrSelection()
        buffer.insert(cursor, text)
        cursor += text.length
        selStart = cursor
        selEnd = cursor
        composing = null
    }

    override fun setComposingText(text: String) {
        replaceComposingOrSelection()
        buffer.insert(cursor, text)
        cursor += text.length
        selStart = cursor
        selEnd = cursor
        composing = text
    }

    override fun finishComposingText() {
        composing = null
    }

    override fun deleteSelectionOrBackspace() {
        if (selStart != selEnd) {
            replaceComposingOrSelection()
            return
        }
        composing = null
        if (cursor == 0) return
        buffer.deleteCharAt(cursor - 1)
        cursor -= 1
        selStart = cursor
        selEnd = cursor
    }

    override fun performEnter() {
        enterCount += 1
        commitText("\n")
    }

    private fun replaceComposingOrSelection() {
        if (selStart != selEnd) {
            val a = min(selStart, selEnd)
            val b = max(selStart, selEnd)
            buffer.delete(a, b)
            cursor = a
            selStart = a
            selEnd = a
            composing = null
            return
        }
        val current = composing
        if (current != null && current.isNotEmpty()) {
            val start = (cursor - current.length).coerceAtLeast(0)
            if (start <= cursor && buffer.substring(start, cursor) == current) {
                buffer.delete(start, cursor)
                cursor = start
            }
            composing = null
            selStart = cursor
            selEnd = cursor
        } else if (current != null) {
            composing = null
        }
    }
}
