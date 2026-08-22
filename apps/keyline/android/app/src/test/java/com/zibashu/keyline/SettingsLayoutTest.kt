package com.zibashu.keyline

import com.zibashu.keyline.settings.SettingsLayout
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SettingsLayoutTest {
    @Test
    fun radioButtonsFillVerticalGroupWidth() {
        val radio = SettingsLayout.radioButton()
        val group = SettingsLayout.radioGroup()
        assertEquals(SettingsLayout.MATCH_PARENT, radio.width)
        assertEquals(SettingsLayout.WRAP_CONTENT, radio.height)
        assertEquals(0f, radio.weight, 0f)
        assertEquals(SettingsLayout.MATCH_PARENT, group.width)
        assertTrue(radio.isHorizontallyVisible)
        assertTrue(group.isHorizontallyVisible)
        assertNotEquals(0, radio.width)
        assertNotEquals(0, group.width)
    }

    @Test
    fun radioSpecsAreWhatSettingsActivityApplies() {
        val applied = SettingsLayout.radioButton()
        assertEquals(-1, applied.width)
        assertEquals(-2, applied.height)
    }
}
