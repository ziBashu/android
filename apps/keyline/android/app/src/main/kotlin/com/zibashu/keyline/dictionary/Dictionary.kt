package com.zibashu.keyline.dictionary

data class DictWord(
    val word: String,
    val frequency: Int,
)

class Dictionary(words: List<DictWord>) {
    private val byWord: Map<String, DictWord> =
        words.associateBy { it.word.lowercase() }

    val size: Int get() = byWord.size

    fun contains(word: String): Boolean = byWord.containsKey(word.lowercase())

    fun get(word: String): DictWord? = byWord[word.lowercase()]

    fun prefix(prefix: String): List<DictWord> {
        val p = prefix.lowercase()
        if (p.isEmpty()) return emptyList()
        return byWord.values.filter { it.word.startsWith(p) }
    }

    companion object {
        fun fromLines(text: String): Dictionary {
            val items = ArrayList<DictWord>()
            for (raw in text.split('\n')) {
                val line = raw.trim()
                if (line.isEmpty() || line.startsWith("#")) continue
                val parts = line.split('\t', ' ').filter { it.isNotEmpty() }
                if (parts.isEmpty()) continue
                val word = parts[0].lowercase()
                val freq = parts.getOrNull(1)?.toIntOrNull() ?: 1
                items += DictWord(word, freq)
            }
            return Dictionary(items)
        }
    }
}
