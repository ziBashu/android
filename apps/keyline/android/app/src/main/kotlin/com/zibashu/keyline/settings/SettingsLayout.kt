package com.zibashu.keyline.settings

/**
 * Layout specs for the native settings screen. Radio options are stacked
 * vertically and must use MATCH_PARENT width — a 0-width weight child in a
 * vertical RadioGroup is untappable.
 */
object SettingsLayout {
    const val MATCH_PARENT: Int = -1
    const val WRAP_CONTENT: Int = -2

    data class Spec(
        val width: Int,
        val height: Int,
        val weight: Float,
    ) {
        val isHorizontallyVisible: Boolean
            get() = width == MATCH_PARENT || width > 0
    }

    fun radioGroup(): Spec = Spec(MATCH_PARENT, WRAP_CONTENT, 0f)

    fun radioButton(): Spec = Spec(MATCH_PARENT, WRAP_CONTENT, 0f)

    fun switchLabel(): Spec = Spec(0, WRAP_CONTENT, 1f)
}
