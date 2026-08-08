package com.zibashu.morphos

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/**
 * Shared prefs bridge between Flutter and [MorphOrientationService].
 * File is private to the MorphOS app process.
 */
object MorphOrientationStore {
    const val PREFS = "morphos_system_v1"
    const val KEY_ENABLED = "system_morph_enabled"
    const val KEY_GLOBAL_MODE = "global_orientation"
    const val KEY_RULES_JSON = "package_rules_json"
    const val KEY_LAST_PACKAGE = "last_foreground_package"
    const val KEY_LAST_MODE = "last_applied_mode"

    fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun isEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, value: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, value).apply()
    }

    fun globalMode(context: Context): String =
        prefs(context).getString(KEY_GLOBAL_MODE, "sensor") ?: "sensor"

    fun setGlobalMode(context: Context, mode: String) {
        prefs(context).edit().putString(KEY_GLOBAL_MODE, mode).apply()
    }

    /** packageName → orientation mode */
    fun packageRules(context: Context): Map<String, String> {
        val raw = prefs(context).getString(KEY_RULES_JSON, "{}") ?: "{}"
        return try {
            val obj = JSONObject(raw)
            val out = mutableMapOf<String, String>()
            val keys = obj.keys()
            while (keys.hasNext()) {
                val k = keys.next()
                out[k] = obj.optString(k, "sensor")
            }
            out
        } catch (_: Exception) {
            emptyMap()
        }
    }

    fun setPackageRules(context: Context, rules: Map<String, String>) {
        val obj = JSONObject()
        for ((k, v) in rules) {
            if (k.isNotBlank()) obj.put(k, v)
        }
        prefs(context).edit().putString(KEY_RULES_JSON, obj.toString()).apply()
    }

    fun setLastForeground(context: Context, packageName: String?) {
        prefs(context).edit()
            .putString(KEY_LAST_PACKAGE, packageName)
            .apply()
    }

    fun lastForeground(context: Context): String? =
        prefs(context).getString(KEY_LAST_PACKAGE, null)

    fun setLastMode(context: Context, mode: String) {
        prefs(context).edit().putString(KEY_LAST_MODE, mode).apply()
    }

    fun lastMode(context: Context): String? =
        prefs(context).getString(KEY_LAST_MODE, null)
}
