package com.zibashu.keyline

import com.zibashu.keyline.KeylineFixtures.press
import com.zibashu.keyline.KeylineFixtures.type
import com.zibashu.keyline.input.ShiftMode
import com.zibashu.keyline.layout.EnglishLayouts
import com.zibashu.keyline.layout.KeyRect
import com.zibashu.keyline.layout.PopupPlacement
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ShiftAndLongPressTest {
    @Test
    fun shiftThenLetterYieldsUppercaseThenReturnsToLowercase() {
        val editor = FakeEditor()
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        controller.press("shift", 0)
        assertEquals(ShiftMode.SHIFTED, controller.shiftMode)
        controller.press("a", 50)
        controller.press("b", 80)
        assertEquals("Ab", editor.text)
        assertEquals(ShiftMode.OFF, controller.shiftMode)
    }

    @Test
    fun doubleTapShiftStaysCapsLock() {
        val editor = FakeEditor()
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        controller.press("shift", 0)
        controller.press("shift", 200)
        assertEquals(ShiftMode.CAPS_LOCK, controller.shiftMode)
        controller.press("a", 300)
        controller.press("b", 320)
        assertEquals("AB", editor.text)
        assertEquals(ShiftMode.CAPS_LOCK, controller.shiftMode)
    }

    @Test
    fun longPressTableForVowelsAndNC() {
        val a = EnglishLayouts.alphabet.findKey("a")!!
        assertTrue(a.alternates.containsAll(listOf("à", "á", "â", "ä", "æ")))
        val e = EnglishLayouts.alphabet.findKey("e")!!
        assertTrue(e.alternates.containsAll(listOf("è", "é", "ê", "ë")))
        val i = EnglishLayouts.alphabet.findKey("i")!!
        assertTrue(i.alternates.containsAll(listOf("ì", "í", "î", "ï")))
        val o = EnglishLayouts.alphabet.findKey("o")!!
        assertTrue(o.alternates.containsAll(listOf("ò", "ó", "ô", "ö")))
        val u = EnglishLayouts.alphabet.findKey("u")!!
        assertTrue(u.alternates.containsAll(listOf("ù", "ú", "û", "ü")))
        val n = EnglishLayouts.alphabet.findKey("n")!!
        assertTrue(n.alternates.contains("ñ"))
        val c = EnglishLayouts.alphabet.findKey("c")!!
        assertTrue(c.alternates.contains("ç"))
    }

    @Test
    fun pickAlternateCommitsAccent() {
        val editor = FakeEditor()
        val controller = KeylineFixtures.controller(editor)
        controller.onStartInput()
        controller.pickAlternate("é")
        controller.press("space")
        assertTrue(editor.text.startsWith("é"))
    }

    @Test
    fun popupClampsToLeftAndRightEdges() {
        val key = EnglishLayouts.alphabet.findKey("a")!!
        val leftKey = KeyRect(key, 0, 40, 40, 80)
        val left = PopupPlacement.place(leftKey, 200, 48, 360, 240)
        assertEquals(0, left.x)
        assertTrue(left.x + left.width <= 360)

        val rightKey = KeyRect(key, 330, 40, 360, 80)
        val right = PopupPlacement.place(rightKey, 200, 48, 360, 240)
        assertEquals(160, right.x)
        assertTrue(right.x + right.width <= 360)

        val topKey = KeyRect(key, 100, 0, 140, 30)
        val flipped = PopupPlacement.place(topKey, 80, 40, 360, 240)
        assertTrue(flipped.y >= topKey.bottom)
    }
}
