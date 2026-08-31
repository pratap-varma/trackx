package com.example.trackx.trackx

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class TrackXWidgetProvider : AppWidgetProvider() {

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
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val thisAppWidget = ComponentName(context.packageName, TrackXWidgetProvider::class.java.name)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget)
        if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.trackx_widget_layout)
            val prefs = context.getSharedPreferences("TrackXWidgetPrefs", Context.MODE_PRIVATE)

            val attendance = prefs.getString("overallAttendance", "") ?: ""
            val classesToday = prefs.getInt("classesToday", 0)
            val nextClassName = prefs.getString("nextClassName", "") ?: ""
            val nextClassTime = prefs.getString("nextClassTime", "") ?: ""
            val nextClassRoom = prefs.getString("nextClassRoom", "") ?: ""
            val tasksPending = prefs.getInt("tasksPending", 0)

            views.setTextViewText(R.id.widget_title, "TrackX")

            // Badge text
            if (attendance.isNotEmpty()) {
                views.setTextViewText(R.id.widget_badge, "$attendance ATT")
            } else {
                views.setTextViewText(R.id.widget_badge, "ACTIVE")
            }

            // Schedule title & subtitle
            if (nextClassTime.isNotEmpty()) {
                views.setTextViewText(R.id.widget_status_title, "NEXT CLASS • $nextClassTime")
            } else if (classesToday > 0) {
                views.setTextViewText(R.id.widget_status_title, "TODAY'S SCHEDULE")
            } else {
                views.setTextViewText(R.id.widget_status_title, "TODAY'S SCHEDULE")
            }

            if (nextClassName.isNotEmpty() && nextClassName != "None") {
                val subtitle = if (nextClassRoom.isNotEmpty()) "$nextClassName ($nextClassRoom)" else nextClassName
                views.setTextViewText(R.id.widget_status_subtitle, subtitle)
            } else if (classesToday == 0) {
                views.setTextViewText(R.id.widget_status_subtitle, "No classes scheduled today")
            } else {
                views.setTextViewText(R.id.widget_status_subtitle, "All classes completed for today")
            }

            // Footer summary
            val footerText = when {
                classesToday > 0 && tasksPending > 0 -> "$classesToday classes • $tasksPending tasks pending"
                classesToday > 0 -> "$classesToday classes scheduled today"
                tasksPending > 0 -> "$tasksPending tasks pending"
                else -> "Track Attendance & Plan Tasks"
            }
            views.setTextViewText(R.id.widget_action_text, footerText)

            // Intent to open MainActivity when widget is clicked
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
