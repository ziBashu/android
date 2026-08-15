package com.zibashu.morphos

import android.service.notification.StatusBarNotification

object MorphNotificationStore {
    private val lock = Any()
    private val items = LinkedHashMap<String, Map<String, Any?>>()
    private var mediaHintRow: Map<String, Any?>? = null

    fun upsert(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val title = extras?.getCharSequence("android.title")?.toString().orEmpty()
        val text = extras?.getCharSequence("android.text")?.toString().orEmpty()
        if (title.isBlank() && text.isBlank()) return
        val category = sbn.notification.category ?: ""
        val template = extras?.getString("android.template").orEmpty()
        val row = mapOf(
            "key" to sbn.key,
            "packageName" to sbn.packageName,
            "title" to title.ifBlank { sbn.packageName },
            "body" to text,
            "category" to category,
            "template" to template,
        )
        synchronized(lock) {
            items[sbn.key] = row
            if (isMediaStyle(category, template)) {
                mediaHintRow = row
            }
            while (items.size > 24) {
                val first = items.keys.first()
                items.remove(first)
            }
        }
    }

    fun remove(key: String) {
        synchronized(lock) {
            items.remove(key)
            if (mediaHintRow?.get("key") == key) mediaHintRow = null
        }
    }

    fun mediaHint(): Map<String, Any?>? {
        val row = synchronized(lock) { mediaHintRow }
            ?: list().firstOrNull { isMediaStyle("${it["category"]}", "${it["template"]}") }
            ?: return null
        val title = (row["title"] as? String).orEmpty()
        val body = (row["body"] as? String).orEmpty()
        return mapOf(
            "kind" to "music",
            "title" to title.ifBlank { "Now playing" },
            "subtitle" to body,
            "playing" to true,
            "progress" to 0.0,
            "expanded" to false,
            "elapsedLabel" to "",
        )
    }

    private fun isMediaStyle(category: String, template: String): Boolean {
        return category == android.app.Notification.CATEGORY_TRANSPORT ||
            template.contains("MediaStyle") ||
            template.contains("DecoratedMediaCustomViewStyle")
    }

    fun list(): List<Map<String, Any?>> {
        synchronized(lock) {
            return items.values.toList()
        }
    }

    fun islandHint(): Map<String, Any?>? {
        val rows = list()
        for (row in rows) {
            val cat = (row["category"] as? String).orEmpty()
            val title = (row["title"] as? String).orEmpty()
            val body = (row["body"] as? String).orEmpty()
            val hay = "$title $body $cat".lowercase()
            if (cat == "call" || hay.contains("incoming call") || hay.contains("ongoing call")) {
                return mapOf(
                    "kind" to "call",
                    "title" to title.ifBlank { "Call" },
                    "subtitle" to body,
                    "elapsedLabel" to "",
                    "expanded" to false,
                    "progress" to 0.0,
                    "playing" to false,
                )
            }
            if (hay.contains("recording") || hay.contains("录制")) {
                return mapOf(
                    "kind" to "recording",
                    "title" to "Recording",
                    "elapsedLabel" to body,
                    "expanded" to false,
                    "progress" to 0.0,
                    "playing" to false,
                    "subtitle" to "",
                )
            }
            if (hay.contains("turn ") || hay.contains("navigation") || cat == "navigation") {
                return mapOf(
                    "kind" to "navigation",
                    "title" to title.ifBlank { "Navigation" },
                    "subtitle" to body,
                    "expanded" to false,
                    "progress" to 0.0,
                    "playing" to false,
                    "elapsedLabel" to "",
                )
            }
            if (hay.contains("timer") || hay.contains("countdown")) {
                return mapOf(
                    "kind" to "timer",
                    "title" to "Timer",
                    "elapsedLabel" to body.ifBlank { title },
                    "expanded" to false,
                    "progress" to 0.0,
                    "playing" to false,
                    "subtitle" to "",
                )
            }
            if (hay.contains("download") || hay.contains("%")) {
                val pct = Regex("""(\d{1,3})\s*%""").find(hay)?.groupValues?.getOrNull(1)
                    ?.toIntOrNull()
                if (pct != null) {
                    return mapOf(
                        "kind" to "download",
                        "title" to title.ifBlank { "Download" },
                        "progress" to (pct.coerceIn(0, 100) / 100.0),
                        "expanded" to false,
                        "playing" to false,
                        "subtitle" to "",
                        "elapsedLabel" to "",
                    )
                }
            }
        }
        return null
    }
}
