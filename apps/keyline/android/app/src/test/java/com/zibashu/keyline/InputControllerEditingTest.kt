package com.zibashu.keyline

import com.zibashu.keyline.KeylineFixtures.press
import com.zibashu.keyline.KeylineFixtures.type
import com.zibashu.keyline.input.KeyboardLayer
import com.zibashu.keyline.settings.KeylineSettingsSnapshot
import com.zibashu.keyline.settings.KeyboardHeight
import com.zibashu.keyline.settings.KeySpacing
import com.zibashu.keyline.settings.ThemeMode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class InputControllerEditingTest {
    @Test
    fun insertBackspaceSpaceEnterAndSelection() {
        val editor = FakeEditor()
        val settings = KeylineSettingsSnapshot.defaults.copy(
            autoCapitalization = false,
            suggestions = false,
            autoCorrection = false,
        )
        val controller = KeylineFixtures.controller(editor, settings)
        controller.onStartInput()
        controller.type("hi")
        controller.press("space")
        assertEquals("hi ", editor.text)
        controller.press("backspace")
        assertEquals("hi", editor.text)
        editor.select(0, 2)
        controller.press("backspace")
        assertEquals("", editor.text)
        controller.type("ab")
        editor.select(1, 1)
        editor.setText("ab", 1)
        controller.press("x")
        assertEquals("axb", editor.text)
        editor.setText(editor.text, editor.text.length)
        controller.press("enter")
        assertTrue(editor.text.endsWith("\n"))
        assertEquals(1, editor.enterCount)
    }

    @Test
    fun alphabetToSymbolsAndBack() {
        val editor = FakeEditor()
        val settings = KeylineSettingsSnapshot.defaults.copy(
            autoCapitalization = false,
            suggestions = false,
        )
        val controller = KeylineFixtures.controller(editor, settings)
        controller.onStartInput()
        controller.press("mode_symbols")
        assertEquals(KeyboardLayer.SYMBOLS, controller.layer)
        controller.press("1")
        controller.press("!")
        controller.press("mode_alphabet")
        assertEquals(KeyboardLayer.ALPHABET, controller.layer)
        assertEquals("1!", editor.text)
    }

    @Test
    fun hideCommitsComposingAndReopenStartsClean() {
        val editor = FakeEditor()
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        controller.type("hel")
        assertEquals("hel", editor.text)
        controller.onHide()
        assertEquals("hel", editor.text)
        controller.onStartInput(restarting = false)
        assertEquals("", controller.composingText)
        controller.type("x")
        assertTrue(editor.text.endsWith("x") || editor.text.contains("x"))
    }

    @Test
    fun settingsDefaultsMatchV1() {
        val d = KeylineSettingsSnapshot.defaults
        assertEquals(ThemeMode.SYSTEM, d.theme)
        assertEquals(KeyboardHeight.NORMAL, d.height)
        assertEquals(KeySpacing.NORMAL, d.spacing)
        assertEquals(true, d.vibration)
        assertEquals(false, d.sound)
        assertEquals(true, d.suggestions)
        assertEquals(true, d.autoCorrection)
        assertEquals(true, d.autoCapitalization)
        assertEquals("en", d.languageId)
    }
}
