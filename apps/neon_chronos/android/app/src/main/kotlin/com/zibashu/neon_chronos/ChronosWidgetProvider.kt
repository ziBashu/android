package com.zibashu.neon_chronos

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ChronosWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.chronos_widget).apply {
                setTextViewText(
                    R.id.widget_time,
                    widgetData.getString("time", "--:--") ?: "--:--",
                )
                setTextViewText(
                    R.id.widget_title,
                    widgetData.getString("title", "NEON CHRONOS") ?: "NEON CHRONOS",
                )
                setTextViewText(
                    R.id.widget_subtitle,
                    widgetData.getString("subtitle", "SYSTEM NORMAL") ?: "SYSTEM NORMAL",
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
