package com.zibashu.keyline

import com.zibashu.keyline.ime.LongPressSession
import com.zibashu.keyline.ime.PopupCell
import com.zibashu.keyline.ime.PopupCells
import com.zibashu.keyline.layout.EnglishLayouts
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LongPressSessionTest {
    private fun aCells(): List<PopupCell> {
        val alts = EnglishLayouts.alphabet.findKey("a")!!.alternates
        assertEquals(listOf("à", "á", "â", "ä", "æ"), alts)
        return alts.mapIndexed { i, token ->
            PopupCell(token, left = i * 40, top = 0, right = i * 40 + 40, bottom = 40)
        }
    }

    @Test
    fun oneFingerSlideSelectsAccentWithoutBase() {
        val session = LongPressSession()
        session.start(aCells())
        session.move(x = 50, y = 20)
        val result = session.up()
        assertEquals(LongPressSession.UpResult.Alternate("á"), result)
        assertFalse(result is LongPressSession.UpResult.CommitBase)
    }

    @Test
    fun eachAAlternateIsSelectable() {
        val session = LongPressSession()
        val cells = aCells()
        val got = cells.map { cell ->
            session.start(cells)
            session.move((cell.left + cell.right) / 2, 10)
            (session.up() as LongPressSession.UpResult.Alternate).token
        }
        assertEquals(listOf("à", "á", "â", "ä", "æ"), got)
    }

    @Test
    fun releaseAfterPopupWithNoHoverDoesNotCommitBase() {
        val session = LongPressSession()
        session.start(aCells())
        val result = session.up()
        assertEquals(LongPressSession.UpResult.Nothing, result)
    }

    @Test
    fun tapWithoutLongPressStillCommitsBase() {
        val session = LongPressSession()
        assertEquals(LongPressSession.UpResult.CommitBase, session.up())
    }

    @Test
    fun pickThenUpDoesNotCommitBase() {
        val session = LongPressSession()
        session.start(aCells())
        session.pick("æ")
        val result = session.up()
        assertEquals(LongPressSession.UpResult.Alternate("æ"), result)
    }

    @Test
    fun cancelAfterPopupDoesNotCommitBaseOnUp() {
        val session = LongPressSession()
        session.start(aCells())
        session.cancel()
        assertEquals(LongPressSession.UpResult.Nothing, session.up())
    }

    @Test
    fun popupCellsRowMatchesShippedAlternatePopupLayout() {
        val alts = EnglishLayouts.alphabet.findKey("a")!!.alternates
        val cells = PopupCells.row(alts, originX = 10, originY = 20, pad = 8, cell = 40)
        assertEquals("á", cells[1].token)
        val session = LongPressSession()
        session.start(cells)
        session.move(10 + 8 + 40 + 20, 20 + 8 + 10)
        assertEquals(LongPressSession.UpResult.Alternate("á"), session.up())
    }
}
