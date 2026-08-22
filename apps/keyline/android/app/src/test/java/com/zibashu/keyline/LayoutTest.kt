package com.zibashu.keyline

import com.zibashu.keyline.layout.EnglishLayouts
import com.zibashu.keyline.layout.KeyType
import com.zibashu.keyline.layout.LayoutEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class LayoutTest {
    @Test
    fun qwertyRowsMatchSpec() {
        val rows = EnglishLayouts.alphabet.rows
        assertEquals("qwertyuiop", rows[0].keys.joinToString("") { it.output })
        assertEquals("asdfghjkl", rows[1].keys.joinToString("") { it.output })
        val row3 = rows[2].keys
        assertEquals("shift", row3.first().id)
        assertEquals("zxcvbnm", row3.drop(1).dropLast(1).joinToString("") { it.output })
        assertEquals("backspace", row3.last().id)
        val bottom = rows[3].keys.map { it.id }
        assertEquals(
            listOf("mode_symbols", "comma", "space", "period", "enter"),
            bottom,
        )
    }

    @Test
    fun alphabetHasRequiredSpecialKeys() {
        val ids = EnglishLayouts.alphabet.allKeys().map { it.id }.toSet()
        assertTrue(ids.containsAll(listOf("shift", "backspace", "space", "enter", "mode_symbols", "comma", "period")))
        val letters = ('a'..'z').map { it.toString() }
        assertTrue(ids.containsAll(letters))
    }

    @Test
    fun symbolLayerHasDigitsAndRequiredPunctuation() {
        val outputs = EnglishLayouts.symbols.allKeys()
            .filter { it.type == KeyType.CHARACTER }
            .map { it.output }
            .toSet()
        for (d in 0..9) {
            assertTrue("missing digit $d", outputs.contains(d.toString()))
        }
        val punct = listOf(
            "!", "?", "@", "#", "$", "%", "&", "*", "(", ")",
            "-", "_", "+", "=", "/", ":", ";", "\"", "'", ",", ".",
            "<", ">", "[", "]", "{", "}", "\\",
        )
        for (p in punct) {
            assertTrue("missing punctuation $p", outputs.contains(p))
        }
        assertNotNull(EnglishLayouts.symbols.findKey("mode_alphabet"))
    }

    @Test
    fun spaceIsDominantBottomKey() {
        val bottom = EnglishLayouts.alphabet.rows.last().keys
        val space = bottom.first { it.id == "space" }
        assertTrue(bottom.filter { it.id != "space" }.all { it.weight < space.weight })
    }

    @Test
    fun keyRectsDoNotOverlapAtPhoneWidths() {
        val widths = listOf(720, 1080, 1440)
        val layouts = listOf(EnglishLayouts.alphabet, EnglishLayouts.symbols)
        for (layout in layouts) {
            for (width in widths) {
                val rects = LayoutEngine.measure(layout, width, 400, gapPx = 8)
                assertTrue("${layout.id} @$width produced no keys", rects.isNotEmpty())
                for (rect in rects) {
                    assertTrue("${rect.key.id} left", rect.left >= 0)
                    assertTrue("${rect.key.id} top", rect.top >= 0)
                    assertTrue("${rect.key.id} right", rect.right <= width)
                    assertTrue("${rect.key.id} bottom", rect.bottom <= 400)
                    assertTrue("${rect.key.id} has size", rect.width > 0 && rect.height > 0)
                }
                for (i in rects.indices) {
                    for (j in i + 1 until rects.size) {
                        assertFalse(
                            "${layout.id} @$width overlap ${rects[i].key.id}/${rects[j].key.id}",
                            rects[i].overlaps(rects[j]),
                        )
                    }
                }
                val lastRowIds = layout.rows.last().keys.map { it.id }.toSet()
                val bottom = rects.filter { it.key.id in lastRowIds }
                val space = bottom.first { it.key.id == "space" }
                assertTrue(
                    "space should be widest on bottom row @ $width",
                    bottom.filter { it.key.id != "space" }.all { it.width < space.width },
                )
            }
        }
    }
}
