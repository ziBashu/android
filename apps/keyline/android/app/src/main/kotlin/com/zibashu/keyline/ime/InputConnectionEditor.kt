package com.zibashu.keyline.ime

import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import com.zibashu.keyline.input.InputKinds
import com.zibashu.keyline.input.KeylineEditor

class InputConnectionEditor(
    private val connection: () -> InputConnection?,
    var editorInfo: EditorInfo,
) : KeylineEditor {
    override val inputType: Int
        get() = editorInfo.inputType

    override fun getTextBeforeCursor(n: Int): String =
        connection()?.getTextBeforeCursor(n, 0)?.toString() ?: ""

    override fun getTextAfterCursor(n: Int): String =
        connection()?.getTextAfterCursor(n, 0)?.toString() ?: ""

    override fun getSelectedText(): String =
        connection()?.getSelectedText(0)?.toString() ?: ""

    override fun commitText(text: String) {
        connection()?.commitText(text, 1)
    }

    override fun setComposingText(text: String) {
        connection()?.setComposingText(text, 1)
    }

    override fun finishComposingText() {
        connection()?.finishComposingText()
    }

    override fun deleteSelectionOrBackspace() {
        val ic = connection() ?: return
        val selected = ic.getSelectedText(0)
        if (!selected.isNullOrEmpty()) {
            ic.commitText("", 1)
        } else {
            ic.deleteSurroundingText(1, 0)
        }
    }

    override fun performEnter() {
        val ic = connection() ?: return
        val action = editorInfo.imeOptions and EditorInfo.IME_MASK_ACTION
        val multiline = InputKinds.isMultiline(editorInfo.inputType)
        if (multiline && (action == EditorInfo.IME_ACTION_NONE ||
                action == EditorInfo.IME_ACTION_UNSPECIFIED)
        ) {
            ic.commitText("\n", 1)
            return
        }
        val toSend = if (action == EditorInfo.IME_ACTION_NONE ||
            action == EditorInfo.IME_ACTION_UNSPECIFIED
        ) {
            EditorInfo.IME_ACTION_DONE
        } else {
            action
        }
        val acted = ic.performEditorAction(toSend)
        if (!acted && multiline) {
            ic.commitText("\n", 1)
        }
    }
}
