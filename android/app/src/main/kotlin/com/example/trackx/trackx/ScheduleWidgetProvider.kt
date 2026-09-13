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

class ScheduleWidgetProvider : AppWidgetProvider() {

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
            val thisAppWidget = ComponentName(context.packageName, ScheduleWidgetProvider::class.java.name)
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
                val views = RemoteViews(context.packageName, R.layout.widget_schedule_layout)
                val prefs = context.getSharedPreferences("TrackXWidgetPrefs", Context.MODE_PRIVATE)

                val dayText = prefs.getString("scheduleDay", "DAILY SCHEDULE") ?: "DAILY SCHEDULE"
                val badgeText = prefs.getString("scheduleBadge", "TODAY") ?: "TODAY"
                val summaryText = prefs.getString("scheduleSummary", "Tap to view full timetable") ?: "Tap to view full timetable"
                val slotsJson = prefs.getString("scheduleSlotsJson", null)

                views.setTextViewText(R.id.widget_sch_day, dayText)
                views.setTextViewText(R.id.widget_sch_badge, badgeText)
                views.setTextViewText(R.id.widget_sch_summary, summaryText)

                // Theme & Appearance styling
                val isDark = prefs.getBoolean("isDark", true)
                val bgDrawable = if (isDark) R.drawable.widget_bg_dark else R.drawable.widget_bg_light
                val cardDrawable = if (isDark) R.drawable.widget_inner_card_bg else R.drawable.widget_inner_card_bg_light
                val rowDrawable = if (isDark) R.drawable.widget_row_bg else R.drawable.widget_row_bg_light

                views.setInt(R.id.widget_sch_root, "setBackgroundResource", bgDrawable)
                views.setInt(R.id.widget_sch_empty_container, "setBackgroundResource", cardDrawable)

                val dayColor = if (isDark) android.graphics.Color.parseColor("#94A3B8") else android.graphics.Color.parseColor("#64748B")
                val summaryColor = if (isDark) android.graphics.Color.parseColor("#64748B") else android.graphics.Color.parseColor("#94A3B8")
                val primaryTextColor = if (isDark) android.graphics.Color.parseColor("#FFFFFF") else android.graphics.Color.parseColor("#0F172A")
                val subTextColor = if (isDark) android.graphics.Color.parseColor("#94A3B8") else android.graphics.Color.parseColor("#64748B")
                val statusTextColor = if (isDark) android.graphics.Color.parseColor("#64748B") else android.graphics.Color.parseColor("#94A3B8")

                views.setTextColor(R.id.widget_sch_day, dayColor)
                views.setTextColor(R.id.widget_sch_summary, summaryColor)
                views.setTextColor(R.id.widget_sch_empty_title, primaryTextColor)

                val rowIds = intArrayOf(
                    R.id.widget_sch_row_1,
                    R.id.widget_sch_row_2,
                    R.id.widget_sch_row_3,
                    R.id.widget_sch_row_4,
                    R.id.widget_sch_row_5
                )
                val badgeIds = intArrayOf(
                    R.id.widget_sch_p1_badge,
                    R.id.widget_sch_p2_badge,
                    R.id.widget_sch_p3_badge,
                    R.id.widget_sch_p4_badge,
                    R.id.widget_sch_p5_badge
                )
                val nameIds = intArrayOf(
                    R.id.widget_sch_p1_name,
                    R.id.widget_sch_p2_name,
                    R.id.widget_sch_p3_name,
                    R.id.widget_sch_p4_name,
                    R.id.widget_sch_p5_name
                )
                val timeIds = intArrayOf(
                    R.id.widget_sch_p1_time,
                    R.id.widget_sch_p2_time,
                    R.id.widget_sch_p3_time,
                    R.id.widget_sch_p4_time,
                    R.id.widget_sch_p5_time
                )
                val statusIds = intArrayOf(
                    R.id.widget_sch_p1_status,
                    R.id.widget_sch_p2_status,
                    R.id.widget_sch_p3_status,
                    R.id.widget_sch_p4_status,
                    R.id.widget_sch_p5_status
                )

                // Style all rows with dynamic theme
                for (i in 0 until 5) {
                    views.setInt(rowIds[i], "setBackgroundResource", rowDrawable)
                    views.setTextColor(nameIds[i], primaryTextColor)
                    views.setTextColor(timeIds[i], subTextColor)
                    views.setTextColor(statusIds[i], statusTextColor)
                }

                var hasSlots = false
                if (!slotsJson.isNullOrEmpty()) {
                    try {
                        val jsonArray = JSONArray(slotsJson)
                        if (jsonArray.length() > 0) {
                            hasSlots = true
                            views.setViewVisibility(R.id.widget_sch_list_container, View.VISIBLE)
                            views.setViewVisibility(R.id.widget_sch_empty_container, View.GONE)

                            for (i in 0 until 5) {
                                if (i < jsonArray.length()) {
                                    val obj = jsonArray.getJSONObject(i)
                                    val badge = obj.optString("badge", "P${i + 1}")
                                    val name = obj.optString("name", "")
                                    val time = obj.optString("time", "")
                                    val status = obj.optString("status", "")

                                    views.setViewVisibility(rowIds[i], View.VISIBLE)
                                    views.setTextViewText(badgeIds[i], badge)
                                    views.setTextViewText(nameIds[i], name)
                                    views.setTextViewText(timeIds[i], time)
                                    views.setTextViewText(statusIds[i], status)
                                } else {
                                    views.setViewVisibility(rowIds[i], View.GONE)
                                }
                            }

                            if (jsonArray.length() > 5) {
                                views.setViewVisibility(R.id.widget_sch_more_text, View.VISIBLE)
                                views.setTextViewText(R.id.widget_sch_more_text, "+${jsonArray.length() - 5} more classes in timetable")
                            } else {
                                views.setViewVisibility(R.id.widget_sch_more_text, View.GONE)
                            }
                        }
                    } catch (_: Exception) {}
                }

                if (!hasSlots) {
                    views.setViewVisibility(R.id.widget_sch_list_container, View.GONE)
                    views.setViewVisibility(R.id.widget_sch_empty_container, View.VISIBLE)
                }

                // 1. Pending Intent to launch the TrackX Timetable screen when clicked
                val launchIntent = (context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent(context, MainActivity::class.java)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", "/timetable")
                }
                val pendingLaunchIntent = PendingIntent.getActivity(
                    context,
                    102,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_sch_root, pendingLaunchIntent)
                views.setOnClickPendingIntent(R.id.widget_sch_logo, pendingLaunchIntent)
                views.setOnClickPendingIntent(R.id.widget_sch_empty_container, pendingLaunchIntent)

                // 2. Pending Intent to refresh widget when "Refresh ↻" or summary is clicked
                val refreshIntent = Intent(context, WidgetRefreshReceiver::class.java).apply {
                    action = WidgetRefreshReceiver.ACTION_REFRESH_WIDGETS
                    putExtra("manual_refresh", true)
                }
                val pendingRefreshIntent = PendingIntent.getBroadcast(
                    context,
                    202,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_sch_action_text, pendingRefreshIntent)
                views.setOnClickPendingIntent(R.id.widget_sch_summary, pendingRefreshIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (_: Exception) {}
        }
    }
}
