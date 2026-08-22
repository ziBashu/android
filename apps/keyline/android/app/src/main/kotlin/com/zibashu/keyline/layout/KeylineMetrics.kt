package com.zibashu.keyline.layout

import com.zibashu.keyline.settings.KeyboardHeight
import com.zibashu.keyline.settings.KeySpacing

object KeylineMetrics {
    const val SUGGESTION_ROW_DP = 40
    const val LONG_PRESS_MS = 400L
    const val BACKSPACE_REPEAT_MS = 70L
    const val BACKSPACE_REPEAT_START_MS = 400L

    fun keyboardHeightDp(height: KeyboardHeight): Int = when (height) {
        KeyboardHeight.COMPACT -> 176
        KeyboardHeight.NORMAL -> 228
        KeyboardHeight.TALL -> 292
    }

    fun gapDp(spacing: KeySpacing): Int = when (spacing) {
        KeySpacing.COMPACT -> 8
        KeySpacing.NORMAL -> 5
        KeySpacing.LARGE -> 3
    }

    fun cornerDp(spacing: KeySpacing): Int = when (spacing) {
        KeySpacing.COMPACT -> 6
        KeySpacing.NORMAL -> 8
        KeySpacing.LARGE -> 10
    }
}
