package com.zibashu.keyline.dictionary

sealed class AutoCorrectDecision {
    data object None : AutoCorrectDecision()
    data class Replace(val word: String) : AutoCorrectDecision()
    data class SuggestOnly(val candidates: List<String>) : AutoCorrectDecision()
}

/**
 * Conservative offline autocorrect. Silent replacement happens only when the
 * typed token is unknown and a single dictionary neighbor dominates.
 */
class Autocorrect(
    private val dictionary: Dictionary,
    private val dominanceRatio: Int = 10,
) {
    fun decide(typed: String): AutoCorrectDecision {
        val token = typed.trim()
        if (token.length < 2 || token.any { !it.isLetter() }) {
            return AutoCorrectDecision.None
        }
        val lower = token.lowercase()
        if (dictionary.contains(lower)) return AutoCorrectDecision.None

        val candidates = edits1(lower)
            .mapNotNull { dictionary.get(it) }
            .distinctBy { it.word }
            .sortedWith(compareByDescending<DictWord> { it.frequency }.thenBy { it.word })

        if (candidates.isEmpty()) return AutoCorrectDecision.None

        val best = candidates.first()
        val second = candidates.getOrNull(1)
        val dominant = second == null || best.frequency >= second.frequency * dominanceRatio
        return if (dominant) {
            AutoCorrectDecision.Replace(preserveCase(token, best.word))
        } else {
            AutoCorrectDecision.SuggestOnly(
                candidates.take(3).map { preserveCase(token, it.word) },
            )
        }
    }

    companion object {
        fun preserveCase(typed: String, replacement: String): String {
            if (typed.isEmpty()) return replacement
            val letters = typed.filter { it.isLetter() }
            if (letters.isNotEmpty() && letters.all { it.isUpperCase() }) {
                return replacement.uppercase()
            }
            if (typed[0].isUpperCase()) {
                return replacement.replaceFirstChar { it.uppercaseChar() }
            }
            return replacement
        }

        fun edits1(word: String): Set<String> {
            val letters = 'a'..'z'
            val out = HashSet<String>()
            for (i in word.indices) {
                out += word.removeRange(i, i + 1)
            }
            for (i in 0 until word.length - 1) {
                out += word.substring(0, i) + word[i + 1] + word[i] + word.substring(i + 2)
            }
            for (i in word.indices) {
                for (c in letters) {
                    if (c != word[i]) {
                        out += word.substring(0, i) + c + word.substring(i + 1)
                    }
                }
            }
            for (i in 0..word.length) {
                for (c in letters) {
                    out += word.substring(0, i) + c + word.substring(i)
                }
            }
            return out
        }
    }
}
