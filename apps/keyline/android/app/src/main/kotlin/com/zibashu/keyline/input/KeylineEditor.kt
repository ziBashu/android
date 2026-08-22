package com.zibashu.keyline.input

/**
 * Testable stand-in for Android's InputConnection. The IME service adapts the
 * real connection; unit tests use a fake buffer.
 */
interface KeylineEditor {
    val inputType: Int
    fun getTextBeforeCursor(n: Int): String
    fun getTextAfterCursor(n: Int): String
    fun getSelectedText(): String
    fun commitText(text: String)
    fun setComposingText(text: String)
    fun finishComposingText()
    fun deleteSelectionOrBackspace()
    fun performEnter()
}
