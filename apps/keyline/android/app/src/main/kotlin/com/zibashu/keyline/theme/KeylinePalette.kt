package com.zibashu.keyline.theme

import com.zibashu.keyline.settings.ThemeMode

/**
 * Central color tokens for KEYLINE. Keyboard drawing reads only from here.
 * XML resources duplicate the same values for the settings screen.
 */
data class KeylineColors(
    val keyboardBackground: Int,
    val keyFill: Int,
    val keyFillPressed: Int,
    val keySpecialFill: Int,
    val keySpecialFillPressed: Int,
    val keyLabel: Int,
    val keyBorder: Int,
    val suggestionBackground: Int,
    val suggestionText: Int,
    val suggestionHighlight: Int,
    val popupBackground: Int,
    val shiftArmed: Int,
    val capsLock: Int,
)

object KeylinePalette {
    val Light = KeylineColors(
        keyboardBackground = 0xFFF3EFE6.toInt(),
        keyFill = 0xFFE7E1D4.toInt(),
        keyFillPressed = 0xFFD9D1C2.toInt(),
        keySpecialFill = 0xFFDCD4C6.toInt(),
        keySpecialFillPressed = 0xFFCFC5B5.toInt(),
        keyLabel = 0xFF2C2A26.toInt(),
        keyBorder = 0xFFD0C8BA.toInt(),
        suggestionBackground = 0xFFF3EFE6.toInt(),
        suggestionText = 0xFF2C2A26.toInt(),
        suggestionHighlight = 0xFF6B5E4E.toInt(),
        popupBackground = 0xFFF7F3EA.toInt(),
        shiftArmed = 0xFFC9BBA8.toInt(),
        capsLock = 0xFFB7A48C.toInt(),
    )

    val Dark = KeylineColors(
        keyboardBackground = 0xFF161616.toInt(),
        keyFill = 0xFF2B2B2B.toInt(),
        keyFillPressed = 0xFF3A3A3A.toInt(),
        keySpecialFill = 0xFF232323.toInt(),
        keySpecialFillPressed = 0xFF303030.toInt(),
        keyLabel = 0xFFE8E4DC.toInt(),
        keyBorder = 0xFF3A3A3A.toInt(),
        suggestionBackground = 0xFF161616.toInt(),
        suggestionText = 0xFFE8E4DC.toInt(),
        suggestionHighlight = 0xFFC4B8A8.toInt(),
        popupBackground = 0xFF2A2A2A.toInt(),
        shiftArmed = 0xFF4A433C.toInt(),
        capsLock = 0xFF5C5349.toInt(),
    )

    fun resolve(theme: ThemeMode, systemDark: Boolean): KeylineColors =
        when (theme) {
            ThemeMode.LIGHT -> Light
            ThemeMode.DARK -> Dark
            ThemeMode.SYSTEM -> if (systemDark) Dark else Light
        }
}
