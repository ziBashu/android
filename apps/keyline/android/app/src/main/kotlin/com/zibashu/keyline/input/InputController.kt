package com.zibashu.keyline.input

import com.zibashu.keyline.dictionary.AutoCorrectDecision
import com.zibashu.keyline.language.LanguageProvider
import com.zibashu.keyline.layout.KeyDefinition
import com.zibashu.keyline.layout.KeyType
import com.zibashu.keyline.layout.KeyboardLayout
import com.zibashu.keyline.settings.KeylineSettingsSnapshot

enum class KeyboardLayer {
    ALPHABET,
    SYMBOLS,
}

class InputController(
    private val editor: KeylineEditor,
    private val language: LanguageProvider,
    var settings: KeylineSettingsSnapshot,
    private val nowMs: () -> Long = { System.currentTimeMillis() },
    val shift: ShiftMachine = ShiftMachine(),
) {
    var layer: KeyboardLayer = KeyboardLayer.ALPHABET
        private set

    private val composing = StringBuilder()

    var suggestions: List<String> = emptyList()
        private set

    var onStateChanged: (() -> Unit)? = null

    val composingText: String get() = composing.toString()

    val shiftMode: ShiftMode get() = shift.mode

    fun currentLayout(): KeyboardLayout =
        if (layer == KeyboardLayer.ALPHABET) language.alphabetLayout else language.symbolLayout

    fun suggestionsSuppressed(): Boolean =
        !settings.suggestions || InputKinds.suppressSuggestions(editor.inputType)

    fun autoCorrectSuppressed(): Boolean =
        !settings.autoCorrection || InputKinds.suppressSuggestions(editor.inputType)

    fun onStartInput(restarting: Boolean = false) {
        composing.clear()
        suggestions = emptyList()
        if (!restarting) {
            layer = KeyboardLayer.ALPHABET
            shift.reset()
        }
        applyAutoCapFromContext()
        emitState()
    }

    fun onHide() {
        flushComposing(suffix = "")
        emitState()
    }

    fun onKey(key: KeyDefinition, now: Long = nowMs()) {
        when (key.type) {
            KeyType.SHIFT -> shift.tapShift(now)
            KeyType.BACKSPACE -> backspace()
            KeyType.SPACE -> space()
            KeyType.ENTER -> enter()
            KeyType.MODE_SYMBOLS -> {
                flushComposing(suffix = "")
                layer = KeyboardLayer.SYMBOLS
            }
            KeyType.MODE_ALPHABET -> {
                layer = KeyboardLayer.ALPHABET
            }
            KeyType.CHARACTER -> typeOutput(key.output.ifEmpty { key.label })
        }
        emitState()
    }

    fun pickSuggestion(word: String) {
        val cased = applyWordCase(word)
        composing.clear()
        editor.commitText("$cased ")
        suggestions = emptyList()
        shift.onCharacterCommitted()
        applyAutoCapFromContext()
        emitState()
    }

    fun pickAlternate(token: String) {
        typeOutput(token)
        emitState()
    }

    private fun typeOutput(raw: String) {
        val out = if (raw.any { it.isLetter() }) shift.apply(raw) else raw
        val compose = !suggestionsSuppressed() && out.length == 1 && out[0].isLetter()
        if (compose) {
            composing.append(out)
            editor.setComposingText(composing.toString())
            suggestions = language.suggestions(composing.toString())
        } else {
            val wordEnding = out.length == 1 && !out[0].isLetter() && !out[0].isDigit() && out[0] != '\''
            if (wordEnding) {
                flushComposing(suffix = out)
            } else {
                flushComposing(suffix = "")
                editor.commitText(out)
                suggestions = emptyList()
            }
        }
        if (out.any { it.isLetter() }) {
            shift.onCharacterCommitted()
        }
        applyAutoCapFromContext()
    }

    private fun space() {
        flushComposing(suffix = " ")
        applyAutoCapFromContext()
    }

    private fun enter() {
        flushComposing(suffix = "")
        suggestions = emptyList()
        editor.performEnter()
        applyAutoCapFromContext()
    }

    private fun backspace() {
        if (editor.getSelectedText().isNotEmpty()) {
            composing.clear()
            suggestions = emptyList()
            editor.deleteSelectionOrBackspace()
            applyAutoCapFromContext()
            return
        }
        if (composing.isNotEmpty()) {
            composing.deleteAt(composing.lastIndex)
            if (composing.isEmpty()) {
                editor.setComposingText("")
                editor.finishComposingText()
                suggestions = emptyList()
            } else {
                editor.setComposingText(composing.toString())
                suggestions = if (suggestionsSuppressed()) {
                    emptyList()
                } else {
                    language.suggestions(composing.toString())
                }
            }
            return
        }
        editor.deleteSelectionOrBackspace()
        applyAutoCapFromContext()
    }

    private fun flushComposing(suffix: String) {
        if (composing.isEmpty()) {
            if (suffix.isNotEmpty()) editor.commitText(suffix)
            return
        }
        var word = composing.toString()
        var nextSuggestions = emptyList<String>()
        if (!autoCorrectSuppressed()) {
            when (val decision = language.autoCorrect(word)) {
                is AutoCorrectDecision.Replace -> word = decision.word
                is AutoCorrectDecision.SuggestOnly -> nextSuggestions = decision.candidates
                AutoCorrectDecision.None -> Unit
            }
        }
        composing.clear()
        editor.commitText(word + suffix)
        suggestions = nextSuggestions
    }

    private fun applyWordCase(word: String): String {
        val current = composing.toString()
        val letters = current.filter { it.isLetter() }
        return when {
            letters.isNotEmpty() && letters.all { it.isUpperCase() } -> word.uppercase()
            current.isNotEmpty() && current[0].isUpperCase() ->
                word.replaceFirstChar { it.uppercaseChar() }
            shift.mode == ShiftMode.CAPS_LOCK -> word.uppercase()
            else -> word
        }
    }

    fun applyAutoCapFromContext() {
        if (shift.mode == ShiftMode.CAPS_LOCK) return
        if (!settings.autoCapitalization) return
        if (InputKinds.isPassword(editor.inputType)) return
        when (InputKinds.capitalization(editor.inputType)) {
            CapMode.CHARACTERS -> shift.setFromAutoCap(true)
            CapMode.WORDS -> {
                val before = editor.getTextBeforeCursor(2)
                shift.setFromAutoCap(
                    before.isEmpty() || before.endsWith(" ") || before.endsWith("\n"),
                )
            }
            CapMode.SENTENCES -> {
                val before = editor.getTextBeforeCursor(16)
                shift.setFromAutoCap(shouldCapitalizeSentence(before))
            }
            CapMode.NONE -> Unit
        }
    }

    private fun emitState() {
        onStateChanged?.invoke()
    }

    companion object {
        fun shouldCapitalizeSentence(before: String): Boolean {
            var i = before.length - 1
            while (i >= 0 && (before[i] == ' ' || before[i] == '\t')) i--
            if (i < 0) return true
            val c = before[i]
            return c == '.' || c == '!' || c == '?' || c == '\n'
        }
    }
}
