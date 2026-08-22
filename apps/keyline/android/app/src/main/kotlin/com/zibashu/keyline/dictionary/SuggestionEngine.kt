package com.zibashu.keyline.dictionary

class SuggestionEngine(
    private val dictionary: Dictionary,
) {
    fun suggest(prefix: String, limit: Int = 3): List<String> {
        val p = prefix.lowercase()
        if (p.isEmpty()) return emptyList()
        return dictionary.prefix(p)
            .filter { it.word != p }
            .sortedWith(compareByDescending<DictWord> { it.frequency }.thenBy { it.word })
            .take(limit)
            .map { it.word }
    }
}
