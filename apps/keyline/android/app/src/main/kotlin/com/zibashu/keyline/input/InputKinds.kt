package com.zibashu.keyline.input

/**
 * Mirrors android.text.InputType bit flags so the controller can be tested
 * without the Android SDK.
 */
object InputKinds {
    const val TYPE_MASK_CLASS = 0x0000000f
    const val TYPE_CLASS_TEXT = 0x00000001
    const val TYPE_CLASS_NUMBER = 0x00000002
    const val TYPE_MASK_VARIATION = 0x00000ff0
    const val TYPE_TEXT_VARIATION_PASSWORD = 0x00000080
    const val TYPE_TEXT_VARIATION_VISIBLE_PASSWORD = 0x00000090
    const val TYPE_TEXT_VARIATION_WEB_PASSWORD = 0x000000e0
    const val TYPE_NUMBER_VARIATION_PASSWORD = 0x00000010
    const val TYPE_TEXT_FLAG_CAP_CHARACTERS = 0x00001000
    const val TYPE_TEXT_FLAG_CAP_WORDS = 0x00002000
    const val TYPE_TEXT_FLAG_CAP_SENTENCES = 0x00004000
    const val TYPE_TEXT_FLAG_MULTI_LINE = 0x00020000
    const val TYPE_TEXT_FLAG_NO_SUGGESTIONS = 0x00080000

    fun isPassword(inputType: Int): Boolean {
        val variation = inputType and TYPE_MASK_VARIATION
        val clazz = inputType and TYPE_MASK_CLASS
        if (clazz == TYPE_CLASS_TEXT) {
            return variation == TYPE_TEXT_VARIATION_PASSWORD ||
                variation == TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                variation == TYPE_TEXT_VARIATION_WEB_PASSWORD
        }
        if (clazz == TYPE_CLASS_NUMBER) {
            return variation == TYPE_NUMBER_VARIATION_PASSWORD
        }
        return false
    }

    fun suppressSuggestions(inputType: Int): Boolean {
        if (isPassword(inputType)) return true
        return (inputType and TYPE_TEXT_FLAG_NO_SUGGESTIONS) != 0
    }

    fun capitalization(inputType: Int): CapMode {
        if (isPassword(inputType)) return CapMode.NONE
        return when {
            (inputType and TYPE_TEXT_FLAG_CAP_CHARACTERS) != 0 -> CapMode.CHARACTERS
            (inputType and TYPE_TEXT_FLAG_CAP_WORDS) != 0 -> CapMode.WORDS
            (inputType and TYPE_TEXT_FLAG_CAP_SENTENCES) != 0 -> CapMode.SENTENCES
            else -> CapMode.NONE
        }
    }

    fun isMultiline(inputType: Int): Boolean =
        (inputType and TYPE_TEXT_FLAG_MULTI_LINE) != 0
}

enum class CapMode {
    NONE,
    SENTENCES,
    WORDS,
    CHARACTERS,
}
