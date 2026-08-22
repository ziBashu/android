package com.zibashu.keyline

import com.zibashu.keyline.KeylineFixtures.press
import com.zibashu.keyline.KeylineFixtures.type
import com.zibashu.keyline.dictionary.AutoCorrectDecision
import com.zibashu.keyline.dictionary.Autocorrect
import com.zibashu.keyline.dictionary.SuggestionEngine
import com.zibashu.keyline.input.InputKinds
import com.zibashu.keyline.settings.KeylineSettingsSnapshot
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SuggestionAutocorrectTest {
    @Test
    fun helYieldsHelloHelpHelpfulWhenSuggestionsOn() {
        val editor = FakeEditor()
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        controller.type("hel")
        assertEquals(listOf("hello", "help", "helpful"), controller.suggestions)
    }

    @Test
    fun helYieldsNothingWhenSuggestionsOff() {
        val editor = FakeEditor()
        val settings = KeylineSettingsSnapshot.defaults.copy(
            autoCapitalization = false,
            suggestions = false,
        )
        val controller = KeylineFixtures.controller(editor, settings)
        controller.onStartInput()
        controller.type("hel")
        assertTrue(controller.suggestions.isEmpty())
        assertEquals("hel", editor.text)
    }

    @Test
    fun suggestionEngineDirectlyRanksShippedDictionary() {
        val engine = SuggestionEngine(KeylineFixtures.dictionary())
        assertEquals(listOf("hello", "help", "helpful"), engine.suggest("hel"))
    }

    @Test
    fun tehBecomesTheWhenAutocorrectOn() {
        val editor = FakeEditor()
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        controller.type("teh")
        controller.press("space")
        assertEquals("the ", editor.text)
    }

    @Test
    fun tehUnchangedWhenAutocorrectOff() {
        val editor = FakeEditor()
        val settings = KeylineSettingsSnapshot.defaults.copy(
            autoCapitalization = false,
            autoCorrection = false,
        )
        val controller = KeylineFixtures.controller(editor, settings)
        controller.onStartInput()
        controller.type("teh")
        controller.press("space")
        assertEquals("teh ", editor.text)
    }

    @Test
    fun lowConfidenceIsNotSilentlyReplaced() {
        val autocorrect = Autocorrect(KeylineFixtures.dictionary())
        val decision = autocorrect.decide("acc")
        assertTrue(decision is AutoCorrectDecision.SuggestOnly)

        val editor = FakeEditor()
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        controller.type("acc")
        controller.press("space")
        assertEquals("acc ", editor.text)
        assertFalse(editor.text.startsWith("abc"))
    }

    @Test
    fun unknownGibberishIsNotReplaced() {
        val editor = FakeEditor()
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        controller.type("qqq")
        controller.press("space")
        assertEquals("qqq ", editor.text)
    }

    @Test
    fun passwordFieldSuppressesSuggestionsAndAutocorrect() {
        val editor = FakeEditor(
            inputType = InputKinds.TYPE_CLASS_TEXT or InputKinds.TYPE_TEXT_VARIATION_PASSWORD,
        )
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        assertTrue(controller.suggestionsSuppressed())
        assertTrue(controller.autoCorrectSuppressed())
        controller.type("hel")
        assertTrue(controller.suggestions.isEmpty())
        editor.setText("")
        controller.onStartInput()
        controller.type("teh")
        controller.press("space")
        assertEquals("teh ", editor.text)
    }

    @Test
    fun variationPasswordAlsoSuppresses() {
        val editor = FakeEditor(
            inputType = InputKinds.TYPE_CLASS_TEXT or InputKinds.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD,
        )
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        assertTrue(controller.suggestionsSuppressed())
        controller.type("hel")
        assertTrue(controller.suggestions.isEmpty())
    }
}
