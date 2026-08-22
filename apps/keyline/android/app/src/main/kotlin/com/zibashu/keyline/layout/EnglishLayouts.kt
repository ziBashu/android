package com.zibashu.keyline.layout

/**
 * English QWERTY + number/symbol layers. Long-press alternatives live on the
 * key definitions so the popup UI stays data-driven.
 */
object EnglishLayouts {

    val longPress: Map<String, List<String>> = mapOf(
        "a" to listOf("à", "á", "â", "ä", "æ"),
        "e" to listOf("è", "é", "ê", "ë"),
        "i" to listOf("ì", "í", "î", "ï"),
        "o" to listOf("ò", "ó", "ô", "ö"),
        "u" to listOf("ù", "ú", "û", "ü"),
        "n" to listOf("ñ"),
        "c" to listOf("ç"),
    )

    val alphabet: KeyboardLayout = KeyboardLayout(
        id = "en-qwerty",
        rows = listOf(
            KeyboardRow("qwertyuiop".map { letter(it) }),
            KeyboardRow(
                keys = "asdfghjkl".map { letter(it) },
                leadingWeight = 0.45f,
                trailingWeight = 0.45f,
            ),
            KeyboardRow(
                listOf(shiftKey(), *("zxcvbnm".map { letter(it) }.toTypedArray()), backspaceKey()),
            ),
            KeyboardRow(
                listOf(
                    modeSymbols(),
                    punct(",", "comma", "Comma"),
                    spaceKey(),
                    punct(".", "period", "Period"),
                    enterKey(),
                ),
            ),
        ),
    )

    val symbols: KeyboardLayout = KeyboardLayout(
        id = "en-symbols",
        rows = listOf(
            KeyboardRow((0..9).map { digit(it) }),
            KeyboardRow(listOf("!", "?", "@", "#", "$", "%", "&", "*", "(", ")").map { punct(it) }),
            KeyboardRow(
                listOf("-", "_", "+", "=", "/", ":", ";", "\"", "'", "\\").map { punct(it) },
            ),
            KeyboardRow(listOf("[", "]", "{", "}", "<", ">").map { punct(it, weight = 1.2f) }),
            KeyboardRow(
                listOf(
                    modeAlphabet(),
                    punct(",", "comma", "Comma"),
                    spaceKey(),
                    punct(".", "period", "Period"),
                    enterKey(),
                ),
            ),
        ),
    )

    private fun letter(ch: Char): KeyDefinition {
        val lower = ch.lowercaseChar().toString()
        return KeyDefinition(
            id = lower,
            label = lower.uppercase(),
            output = lower,
            alternates = longPress[lower] ?: emptyList(),
            type = KeyType.CHARACTER,
            contentDescription = lower.uppercase(),
        )
    }

    private fun digit(n: Int): KeyDefinition {
        val s = n.toString()
        return KeyDefinition(id = s, label = s, output = s, contentDescription = s)
    }

    private fun punct(
        symbol: String,
        id: String = symbol,
        description: String = symbol,
        weight: Float = 1f,
    ): KeyDefinition = KeyDefinition(
        id = id,
        label = symbol,
        output = symbol,
        type = KeyType.CHARACTER,
        weight = weight,
        contentDescription = description,
    )

    private fun shiftKey() = KeyDefinition(
        id = "shift",
        label = "⇧",
        type = KeyType.SHIFT,
        weight = 1.45f,
        contentDescription = "Shift",
    )

    private fun backspaceKey() = KeyDefinition(
        id = "backspace",
        label = "⌫",
        type = KeyType.BACKSPACE,
        weight = 1.45f,
        contentDescription = "Backspace",
    )

    private fun spaceKey() = KeyDefinition(
        id = "space",
        label = "",
        output = " ",
        type = KeyType.SPACE,
        weight = 4.2f,
        contentDescription = "Space",
    )

    private fun enterKey() = KeyDefinition(
        id = "enter",
        label = "↵",
        type = KeyType.ENTER,
        weight = 1.35f,
        contentDescription = "Enter",
    )

    private fun modeSymbols() = KeyDefinition(
        id = "mode_symbols",
        label = "123",
        type = KeyType.MODE_SYMBOLS,
        weight = 1.35f,
        contentDescription = "Numbers and symbols",
    )

    private fun modeAlphabet() = KeyDefinition(
        id = "mode_alphabet",
        label = "ABC",
        type = KeyType.MODE_ALPHABET,
        weight = 1.35f,
        contentDescription = "Letters",
    )
}
