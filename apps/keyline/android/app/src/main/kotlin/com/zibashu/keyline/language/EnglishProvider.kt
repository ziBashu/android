package com.zibashu.keyline.language

import com.zibashu.keyline.dictionary.AutoCorrectDecision
import com.zibashu.keyline.dictionary.Autocorrect
import com.zibashu.keyline.dictionary.Dictionary
import com.zibashu.keyline.dictionary.SuggestionEngine
import com.zibashu.keyline.layout.EnglishLayouts
import com.zibashu.keyline.layout.KeyboardLayout

class EnglishProvider(
    dictionary: Dictionary,
) : LanguageProvider {
    private val suggestionsEngine = SuggestionEngine(dictionary)
    private val autocorrect = Autocorrect(dictionary)

    override val id: String = ID
    override val displayName: String = "English"
    override val alphabetLayout: KeyboardLayout = EnglishLayouts.alphabet
    override val symbolLayout: KeyboardLayout = EnglishLayouts.symbols

    override fun suggestions(prefix: String, limit: Int): List<String> =
        suggestionsEngine.suggest(prefix, limit)

    override fun autoCorrect(typed: String): AutoCorrectDecision =
        autocorrect.decide(typed)

    companion object {
        const val ID = "en"

        const val FALLBACK_DICT: String =
            "the 1000000\nhello 12000\nhelp 11000\nhelpful 6000\n"
    }
}
