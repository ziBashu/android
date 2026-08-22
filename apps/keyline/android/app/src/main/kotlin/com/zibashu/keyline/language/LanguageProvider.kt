package com.zibashu.keyline.language

import com.zibashu.keyline.dictionary.AutoCorrectDecision
import com.zibashu.keyline.layout.KeyboardLayout

/**
 * Language pack seam. V1 ships English only. Future packs (pinyin, romaji)
 * implement this without changing the IME service.
 */
interface LanguageProvider {
    val id: String
    val displayName: String
    val alphabetLayout: KeyboardLayout
    val symbolLayout: KeyboardLayout
    fun suggestions(prefix: String, limit: Int = 3): List<String>
    fun autoCorrect(typed: String): AutoCorrectDecision
}
