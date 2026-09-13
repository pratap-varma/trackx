package com.example.trackx.trackx

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class ExamsWidgetProvider : AppWidgetProvider() {

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
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisAppWidget = ComponentName(context.packageName, ExamsWidgetProvider::class.java.name)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                for (appWidgetId in appWidgetIds) {
                    updateAppWidget(context, appWidgetManager, appWidgetId)
                }
            }
        } catch (_: Exception) {}
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_exams_layout)
                val prefs = context.getSharedPreferences("TrackXWidgetPrefs", Context.MODE_PRIVATE)

                val headerText = prefs.getString("examsHeader", "EXAMS & EVENTS") ?: "EXAMS & EVENTS"
                val badgeText = prefs.getString("examsBadge", "SCHEDULED") ?: "SCHEDULED"
                val summaryText = prefs.getString("examsSummary", "0 upcoming exams • 0 tasks pending") ?: "0 upcoming exams • 0 tasks pending"
                val examsJson = prefs.getString("examsSlotsJson", null)

                views.setTextViewText(R.id.widget_exam_header, headerText)
                views.setTextViewText(R.id.widget_exam_days_badge, badgeText)
                views.setTextViewText(R.id.widget_exam_summary, summaryText)

                // Theme & Appearance styling
                val isDark = prefs.getBoolean("isDark", true)
                val bgDrawable = if (isDark) R.drawable.widget_bg_dark else R.drawable.widget_bg_light
                val cardDrawable = if (isDark) R.drawable.widget_inner_card_bg else R.drawable.widget_inner_card_bg_light
                val rowDrawable = if (isDark) R.drawable.widget_row_bg else R.drawable.widget_row_bg_light

                views.setInt(R.id.widget_exam_root, "setBackgroundResource", bgDrawable)
                views.setInt(R.id.widget_exam_empty_container, "setBackgroundResource", cardDrawable)

                val headerColor = if (isDark) android.graphics.Color.parseColor("#94A3B8") else android.graphics.Color.parseColor("#64748B")
                val summaryColor = if (isDark) android.graphics.Color.parseColor("#64748B") else android.graphics.Color.parseColor("#94A3B8")
                val primaryTextColor = if (isDark) android.graphics.Color.parseColor("#FFFFFF") else android.graphics.Color.parseColor("#0F172A")
                val subTextColor = if (isDark) android.graphics.Color.parseColor("#94A3B8") else android.graphics.Color.parseColor("#64748B")

                views.setTextColor(R.id.widget_exam_header, headerColor)
                views.setTextColor(R.id.widget_exam_summary, summaryColor)
                views.setTextColor(R.id.widget_exam_empty_title, primaryTextColor)
                views.setTextColor(R.id.widget_exam_empty_subtitle, subTextColor)

                val rowIds = intArrayOf(
                    R.id.widget_exam_row_1,
                    R.id.widget_exam_row_2,
                    R.id.widget_exam_row_3,
                    R.id.widget_exam_row_4,
                    R.id.widget_exam_row_5
                )
                val badgeIds = intArrayOf(
                    R.id.widget_exam_r1_badge,
                    R.id.widget_exam_r2_badge,
                    R.id.widget_exam_r3_badge,
                    R.id.widget_exam_r4_badge,
                    R.id.widget_exam_r5_badge
                )
                val titleIds = intArrayOf(
                    R.id.widget_exam_r1_title,
                    R.id.widget_exam_r2_title,
                    R.id.widget_exam_r3_title,
                    R.id.widget_exam_r4_title,
                    R.id.widget_exam_r5_title
                )
                val subtitleIds = intArrayOf(
                    R.id.widget_exam_r1_subtitle,
                    R.id.widget_exam_r2_subtitle,
                    R.id.widget_exam_r3_subtitle,
                    R.id.widget_exam_r4_subtitle,
                    R.id.widget_exam_r5_subtitle
                )

                // Style all rows with dynamic theme
                for (i in 0 until 5) {
                    views.setInt(rowIds[i], "setBackgroundResource", rowDrawable)
                    views.setTextColor(titleIds[i], primaryTextColor)
                    views.setTextColor(subtitleIds[i], subTextColor)
                }

                var hasEvents = false
                if (!examsJson.isNullOrEmpty()) {
                    try {
                        val jsonArray = JSONArray(examsJson)
                        if (jsonArray.length() > 0) {
                            hasEvents = true
                            views.setViewVisibility(R.id.widget_exam_list_container, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_exam_empty_container, View.GONE)

                            for (i in 0 until 5) {
                                if (i < jsonArray.length()) {
                                    val obj = jsonArray.getJSONObject(i)
                                    val badge = obj.optString("badge", "EXAM")
                                    val title = obj.optString("title", "")
                                    val subtitle = obj.optString("subtitle", "")

                                    views.setViewVisibility(rowIds[i], View.VISIBLE)
                                    views.setTextViewText(badgeIds[i], badge)
                                    views.setTextViewText(titleIds[i], title)
                                    views.setTextViewText(subtitleIds[i], subtitle)
                                } else {
                                    views.setViewVisibility(rowIds[i], View.GONE)
                                }
                            }

                            if (jsonArray.length() > 5) {
                                views.setViewVisibility(R.id.widget_exam_more_text, View.VISIBLE)
                                views.setTextViewText(R.id.widget_exam_more_text, "+${jsonArray.length() - 5} more in Planner")
                            } else {
                                views.setViewVisibility(R.id.widget_exam_more_text, View.GONE)
                            }
                        }
                    } catch (_: Exception) {}
                }

                if (!hasEvents) {
                    views.setViewVisibility(R.id.widget_exam_list_container, View.GONE)
                    views.setViewVisibility(R.id.widget_exam_empty_container, View.VISIBLE)
                }

                // 1. Pending Intent to launch the TrackX Planner screen when clicked
                val launchIntent = (context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent(context, MainActivity::class.java)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", "/planner")
                }
                val pendingLaunchIntent = PendingIntent.getActivity(
                    context,
                    103,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_exam_root, pendingLaunchIntent)
                views.setOnClickPendingIntent(R.id.widget_exam_logo, pendingLaunchIntent)
                views.setOnClickPendingIntent(R.id.widget_exam_empty_container, pendingLaunchIntent)

                // 2. Pending Intent to refresh widget when "Refresh ↻" or summary is clicked
                val refreshIntent = Intent(context, WidgetRefreshReceiver::class.java).apply {
                    action = WidgetRefreshReceiver.ACTION_REFRESH_WIDGETS
                    putExtra("manual_refresh", true)
                }
                val pendingRefreshIntent = PendingIntent.getBroadcast(
                    context,
                    203,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_exam_action_text, pendingRefreshIntent)
                views.setOnClickPendingIntent(R.id.widget_exam_summary, pendingRefreshIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (_: Exception) {}
        }
    }
}
