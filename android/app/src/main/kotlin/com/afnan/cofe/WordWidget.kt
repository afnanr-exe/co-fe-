package com.afnan.cofe

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.util.Calendar

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

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == Intent.ACTION_DATE_CHANGED ||
            intent.action == Intent.ACTION_BOOT_COMPLETED) {
            computeAndSaveTodaysWord(context)
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, WordWidget::class.java))
            onUpdate(context, manager, ids)
        }
    }

    companion object {

        private fun computeAndSaveTodaysWord(context: Context) {
            try {
                val json = context.assets.open("flutter_assets/assets/words.json")
                    .bufferedReader().use { it.readText() }
                val words = JSONArray(json)
                val dayOfYear = Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
                val index = (dayOfYear + 14) % words.length()
                val word = words.getJSONObject(index)

                context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                    .edit()
                    .putString("widget_word_term", word.optString("term", "—"))
                    .putString("widget_word_pos", word.optString("partOfSpeech", ""))
                    .putString("widget_word_definition", word.optString("definition", ""))
                    .apply()
            } catch (e: Exception) {
                // keep showing previous word if anything fails
            }
        }

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

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
