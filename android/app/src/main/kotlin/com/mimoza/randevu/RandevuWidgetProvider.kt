package com.mimoza.randevu

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders the home-screen widget from the App Group shared store written by
 * WidgetService (Dart). The keys here mirror lib/services/widget_service.dart —
 * change one, change both.
 */
class RandevuWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val launchIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(DEEP_LINK),
        )

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.randevu_widget)

            views.setTextViewText(R.id.widget_date, widgetData.getString(KEY_DATE, "") ?: "")

            val total = widgetData.getInt(KEY_TOTAL, 0)
            val remaining = widgetData.getInt(KEY_REMAINING, 0)
            if (remaining > 0) {
                views.setViewVisibility(R.id.widget_count_row, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                views.setTextViewText(R.id.widget_count, remaining.toString())
            } else {
                views.setViewVisibility(R.id.widget_count_row, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                val message =
                    if (total > 0) R.string.widget_empty_done else R.string.widget_empty_none
                views.setTextViewText(R.id.widget_empty, context.getString(message))
            }

            bindSlot(
                views, R.id.widget_slot1, R.id.widget_slot1_time, R.id.widget_slot1_name,
                widgetData.getString(KEY_SLOT1_TIME, "") ?: "",
                widgetData.getString(KEY_SLOT1_NAME, "") ?: "",
            )
            bindSlot(
                views, R.id.widget_slot2, R.id.widget_slot2_time, R.id.widget_slot2_name,
                widgetData.getString(KEY_SLOT2_TIME, "") ?: "",
                widgetData.getString(KEY_SLOT2_NAME, "") ?: "",
            )

            // Tap anywhere → open the app on the Randevu Defteri.
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun bindSlot(
        views: RemoteViews,
        rowId: Int,
        timeId: Int,
        nameId: Int,
        time: String,
        name: String,
    ) {
        if (name.isEmpty()) {
            views.setViewVisibility(rowId, View.GONE)
            return
        }
        views.setViewVisibility(rowId, View.VISIBLE)
        views.setTextViewText(timeId, time)
        views.setTextViewText(nameId, name)
    }

    private companion object {
        const val DEEP_LINK = "mimozarandevu://calendar"
        const val KEY_DATE = "date"
        const val KEY_TOTAL = "total"
        const val KEY_REMAINING = "remaining"
        const val KEY_SLOT1_TIME = "n1_time"
        const val KEY_SLOT1_NAME = "n1_name"
        const val KEY_SLOT2_TIME = "n2_time"
        const val KEY_SLOT2_NAME = "n2_name"
    }
}
