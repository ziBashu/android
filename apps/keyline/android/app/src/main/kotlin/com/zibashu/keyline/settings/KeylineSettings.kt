package com.zibashu.keyline.settings

enum class ThemeMode { SYSTEM, LIGHT, DARK }

enum class KeyboardHeight { COMPACT, NORMAL, TALL }

enum class KeySpacing { COMPACT, NORMAL, LARGE }

data class KeylineSettingsSnapshot(
    val theme: ThemeMode = ThemeMode.SYSTEM,
    val height: KeyboardHeight = KeyboardHeight.NORMAL,
    val spacing: KeySpacing = KeySpacing.NORMAL,
    val vibration: Boolean = true,
    val sound: Boolean = false,
    val suggestions: Boolean = true,
    val autoCorrection: Boolean = true,
    val autoCapitalization: Boolean = true,
    val languageId: String = "en",
) {
    companion object {
        val defaults: KeylineSettingsSnapshot = KeylineSettingsSnapshot()
    }
}
