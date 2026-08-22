package com.zibashu.keyline.language

class LanguageRegistry(
    private val providers: List<LanguageProvider>,
) {
    init {
        require(providers.isNotEmpty()) { "At least one language provider is required" }
    }

    val available: List<LanguageProvider> get() = providers

    fun get(id: String): LanguageProvider =
        providers.firstOrNull { it.id == id } ?: providers.first()
}
