package com.zibashu.keyline.layout

data class KeyboardRow(
    val keys: List<KeyDefinition>,
    val leadingWeight: Float = 0f,
    val trailingWeight: Float = 0f,
)

data class KeyboardLayout(
    val id: String,
    val rows: List<KeyboardRow>,
) {
    fun allKeys(): List<KeyDefinition> = rows.flatMap { it.keys }

    fun findKey(id: String): KeyDefinition? = allKeys().find { it.id == id }
}
