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
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisAppWidget = ComponentName(context.packageName, TrackXWidgetProvider::class.java.name)
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
                val views = RemoteViews(context.packageName, R.layout.trackx_widget_layout)
                val prefs = context.getSharedPreferences("TrackXWidgetPrefs", Context.MODE_PRIVATE)

                val attendance = prefs.getString("overallAttendance", "--%") ?: "--%"
                val badge = prefs.getString("attendanceBadge", "ACTIVE") ?: "ACTIVE"
                val bunkInfo = prefs.getString("attendanceBunkInfo", "") ?: ""
                val nextClassMeta = prefs.getString("nextClassMeta", "TODAY'S SCHEDULE") ?: "TODAY'S SCHEDULE"
                val nextClassName = prefs.getString("nextClassName", "No classes scheduled today") ?: "No classes scheduled today"
                val nextClassRoom = prefs.getString("nextClassRoom", "") ?: ""

                val isDark = prefs.getBoolean("isDark", true)
                val bgDrawable = if (isDark) R.drawable.widget_bg_dark else R.drawable.widget_bg_light
                views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)

                val isLow = badge.contains("LOW", ignoreCase = true) || badge.contains("CRITICAL", ignoreCase = true)
                val isSafe = badge.equals("SAFE", ignoreCase = true) || badge.equals("ON TRACK", ignoreCase = true)
                val badgeDrawable = when {
                    isLow -> R.drawable.widget_badge_red
                    isSafe -> R.drawable.widget_badge_green
                    else -> R.drawable.widget_badge_blue
                }
                val badgeColor = when {
                    isLow -> android.graphics.Color.parseColor("#EF4444")
                    isSafe -> android.graphics.Color.parseColor("#10B981")
                    else -> android.graphics.Color.parseColor("#3B82F6")
                }

                views.setInt(R.id.widget_badge, "setBackgroundResource", badgeDrawable)
                views.setTextColor(R.id.widget_badge, badgeColor)

                val titleColor = if (isDark) android.graphics.Color.parseColor("#FFFFFF") else android.graphics.Color.parseColor("#0F172A")
                val subColor = if (isDark) android.graphics.Color.parseColor("#94A3B8") else android.graphics.Color.parseColor("#64748B")
                val scheduleMetaColor = if (isDark) android.graphics.Color.parseColor("#A5B4FC") else android.graphics.Color.parseColor("#4F46E5")

                views.setTextColor(R.id.widget_title, titleColor)
                views.setTextColor(R.id.widget_status_title, scheduleMetaColor)
                views.setTextColor(R.id.widget_status_subtitle, titleColor)
                views.setTextColor(R.id.widget_action_text, subColor)

                views.setTextViewText(R.id.widget_title, "TrackX")
                views.setTextViewText(R.id.widget_badge, if (attendance != "--%") attendance else badge)
                views.setTextViewText(R.id.widget_status_title, nextClassMeta)
                views.setTextViewText(
                    R.id.widget_status_subtitle,
                    if (nextClassRoom.isNotEmpty()) "$nextClassName • $nextClassRoom" else nextClassName
                )
                views.setTextViewText(
                    R.id.widget_action_text,
                    if (bunkInfo.isNotEmpty()) "$attendance • $bunkInfo" else "Tap to open app"
                )

                // 1. Launch App when widget is tapped
                val launchIntent = (context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent(context, MainActivity::class.java)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingLaunchIntent = PendingIntent.getActivity(
                    context,
                    100,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingLaunchIntent)
                views.setOnClickPendingIntent(R.id.widget_main_logo, pendingLaunchIntent)

                // 2. Refresh widget when refresh button is tapped
                val refreshIntent = Intent(context, WidgetRefreshReceiver::class.java).apply {
                    action = WidgetRefreshReceiver.ACTION_REFRESH_WIDGETS
                    putExtra("manual_refresh", true)
                }
                val pendingRefreshIntent = PendingIntent.getBroadcast(
                    context,
                    200,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_main_action_btn, pendingRefreshIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (_: Exception) {}
        }
    }
}
