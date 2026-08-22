package com.zibashu.keyline.settings

import android.content.Context
import android.content.SharedPreferences

class KeylineSettingsStore(context: Context) {
    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun load(): KeylineSettingsSnapshot = KeylineSettingsSnapshot(
        theme = enumValue(KEY_THEME, ThemeMode.SYSTEM),
        height = enumValue(KEY_HEIGHT, KeyboardHeight.NORMAL),
        spacing = enumValue(KEY_SPACING, KeySpacing.NORMAL),
        vibration = prefs.getBoolean(KEY_VIBRATION, true),
        sound = prefs.getBoolean(KEY_SOUND, false),
        suggestions = prefs.getBoolean(KEY_SUGGESTIONS, true),
        autoCorrection = prefs.getBoolean(KEY_AUTOCORRECT, true),
        autoCapitalization = prefs.getBoolean(KEY_AUTOCAP, true),
        languageId = prefs.getString(KEY_LANGUAGE, "en") ?: "en",
    )

    fun save(snapshot: KeylineSettingsSnapshot) {
        prefs.edit()
            .putString(KEY_THEME, snapshot.theme.name)
            .putString(KEY_HEIGHT, snapshot.height.name)
            .putString(KEY_SPACING, snapshot.spacing.name)
            .putBoolean(KEY_VIBRATION, snapshot.vibration)
            .putBoolean(KEY_SOUND, snapshot.sound)
            .putBoolean(KEY_SUGGESTIONS, snapshot.suggestions)
            .putBoolean(KEY_AUTOCORRECT, snapshot.autoCorrection)
            .putBoolean(KEY_AUTOCAP, snapshot.autoCapitalization)
            .putString(KEY_LANGUAGE, snapshot.languageId)
            .apply()
    }

    fun register(listener: SharedPreferences.OnSharedPreferenceChangeListener) {
        prefs.registerOnSharedPreferenceChangeListener(listener)
    }

    fun unregister(listener: SharedPreferences.OnSharedPreferenceChangeListener) {
        prefs.unregisterOnSharedPreferenceChangeListener(listener)
    }

    private inline fun <reified T : Enum<T>> enumValue(key: String, default: T): T {
        val raw = prefs.getString(key, default.name) ?: default.name
        return enumValues<T>().firstOrNull { it.name == raw } ?: default
    }

    companion object {
        const val PREFS = "keyline_settings"
        const val KEY_THEME = "theme"
        const val KEY_HEIGHT = "height"
        const val KEY_SPACING = "spacing"
        const val KEY_VIBRATION = "vibration"
        const val KEY_SOUND = "sound"
        const val KEY_SUGGESTIONS = "suggestions"
        const val KEY_AUTOCORRECT = "autocorrect"
        const val KEY_AUTOCAP = "autocap"
        const val KEY_LANGUAGE = "language"
    }
}
