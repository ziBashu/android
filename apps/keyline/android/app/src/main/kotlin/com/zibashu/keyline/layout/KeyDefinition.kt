package com.zibashu.keyline.layout

data class KeyDefinition(
    val id: String,
    val label: String,
    val output: String = "",
    val alternates: List<String> = emptyList(),
    val type: KeyType = KeyType.CHARACTER,
    val weight: Float = 1f,
    val contentDescription: String = label,
) {
    val isSpecial: Boolean
        get() = type != KeyType.CHARACTER
}
