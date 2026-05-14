package com.afnan.cofe

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WordWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)

            val term = widgetData.getString("widget_word_term", "—") ?: "—"
            val pos = widgetData.getString("widget_word_pos", "") ?: ""
            val definition = widgetData.getString("widget_word_definition", "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.word_widget)
            views.setTextViewText(R.id.widget_term, term)
            views.setTextViewText(R.id.widget_pos, pos)
            views.setTextViewText(R.id.widget_definition, definition)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
