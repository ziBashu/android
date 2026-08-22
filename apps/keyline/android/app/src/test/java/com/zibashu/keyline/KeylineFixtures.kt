package com.zibashu.keyline

import com.zibashu.keyline.dictionary.Dictionary
import com.zibashu.keyline.input.InputController
import com.zibashu.keyline.input.KeylineEditor
import com.zibashu.keyline.language.EnglishProvider
import com.zibashu.keyline.layout.KeyDefinition
import com.zibashu.keyline.settings.KeylineSettingsSnapshot

object KeylineFixtures {
    const val DICT = """
the 1000000
ten 5000
tea 3000
hello 12000
help 11000
helpful 6000
held 2000
abc 100
adc 90
word 8000
"""

    fun dictionary(): Dictionary = Dictionary.fromLines(DICT)

    fun english(): EnglishProvider = EnglishProvider(dictionary())

    fun controller(
        editor: KeylineEditor,
        settings: KeylineSettingsSnapshot = KeylineSettingsSnapshot.defaults.copy(
            autoCapitalization = false,
        ),
        now: () -> Long = { 0L },
    ): InputController = InputController(
        editor = editor,
        language = english(),
        settings = settings,
        nowMs = now,
    )

    fun InputController.press(id: String, at: Long = 0L) {
        val key = key(id)
        onKey(key, at)
    }

    fun InputController.key(id: String): KeyDefinition =
        currentLayout().findKey(id)
            ?: english().alphabetLayout.findKey(id)
            ?: english().symbolLayout.findKey(id)
            ?: error("missing key $id")

    fun InputController.type(letters: String) {
        for (ch in letters) {
            press(ch.lowercaseChar().toString())
        }
    }
}
