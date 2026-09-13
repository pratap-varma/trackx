package com.example.trackx.trackx

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class AttendanceWidgetProvider : AppWidgetProvider() {

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
            val thisAppWidget = ComponentName(context.packageName, AttendanceWidgetProvider::class.java.name)
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
                val views = RemoteViews(context.packageName, R.layout.widget_attendance_layout)
                val prefs = context.getSharedPreferences("TrackXWidgetPrefs", Context.MODE_PRIVATE)

                val attendance = prefs.getString("overallAttendance", "--%") ?: "--%"
                val badge = prefs.getString("attendanceBadge", "ON TRACK") ?: "ON TRACK"
                val bunkInfo = prefs.getString("attendanceBunkInfo", "Safe to Bunk: -- classes") ?: "Safe to Bunk: -- classes"
                val targetInfo = prefs.getString("attendanceTargetInfo", "Target: 75%") ?: "Target: 75%"
                val ratioInfo = prefs.getString("attendanceRatio", "-- / -- Conducted") ?: "-- / -- Conducted"

                // Theme & Appearance styling
                val isDark = prefs.getBoolean("isDark", true)
                val bgDrawable = if (isDark) R.drawable.widget_bg_dark else R.drawable.widget_bg_light
                val cardDrawable = if (isDark) R.drawable.widget_inner_card_bg else R.drawable.widget_inner_card_bg_light

                views.setInt(R.id.widget_att_root, "setBackgroundResource", bgDrawable)

                val titleColor = if (isDark) android.graphics.Color.parseColor("#94A3B8") else android.graphics.Color.parseColor("#64748B")
                val labelColor = if (isDark) android.graphics.Color.parseColor("#64748B") else android.graphics.Color.parseColor("#94A3B8")
                val bunkColor = if (isDark) android.graphics.Color.parseColor("#E2E8F0") else android.graphics.Color.parseColor("#0F172A")
                val targetColor = if (isDark) android.graphics.Color.parseColor("#94A3B8") else android.graphics.Color.parseColor("#475569")
                val ratioColor = if (isDark) android.graphics.Color.parseColor("#64748B") else android.graphics.Color.parseColor("#94A3B8")

                views.setTextColor(R.id.widget_att_title, titleColor)
                views.setTextColor(R.id.widget_att_status_label, labelColor)
                views.setTextColor(R.id.widget_att_bunk_info, bunkColor)
                views.setTextColor(R.id.widget_att_target_info, targetColor)
                views.setTextColor(R.id.widget_att_ratio, ratioColor)

                // Dynamic percentage and badge styling
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
                val percentageColor = when {
                    isLow -> android.graphics.Color.parseColor("#EF4444")
                    isSafe -> android.graphics.Color.parseColor("#10B981")
                    else -> if (isDark) android.graphics.Color.parseColor("#FFFFFF") else android.graphics.Color.parseColor("#0F172A")
                }

                views.setInt(R.id.widget_att_badge, "setBackgroundResource", badgeDrawable)
                views.setTextColor(R.id.widget_att_badge, badgeColor)
                views.setTextColor(R.id.widget_att_percentage, percentageColor)

                views.setTextViewText(R.id.widget_att_percentage, attendance)
                views.setTextViewText(R.id.widget_att_badge, badge)
                views.setTextViewText(R.id.widget_att_bunk_info, bunkInfo)
                views.setTextViewText(R.id.widget_att_target_info, targetInfo)
                views.setTextViewText(R.id.widget_att_ratio, ratioInfo)

                // 1. Pending Intent to launch the TrackX app when widget body is tapped
                val launchIntent = (context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent(context, MainActivity::class.java)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", "/attendance")
                }
                val pendingLaunchIntent = PendingIntent.getActivity(
                    context,
                    101,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_att_root, pendingLaunchIntent)
                views.setOnClickPendingIntent(R.id.widget_att_logo, pendingLaunchIntent)
                views.setOnClickPendingIntent(R.id.widget_att_percentage, pendingLaunchIntent)
                views.setOnClickPendingIntent(R.id.widget_att_bunk_info, pendingLaunchIntent)

                // 2. Pending Intent to refresh widget when "Tap to refresh ↻" is explicitly clicked
                val refreshIntent = Intent(context, WidgetRefreshReceiver::class.java).apply {
                    action = WidgetRefreshReceiver.ACTION_REFRESH_WIDGETS
                    putExtra("manual_refresh", true)
                }
                val pendingRefreshIntent = PendingIntent.getBroadcast(
                    context,
                    201,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_att_action_text, pendingRefreshIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (_: Exception) {}
        }
    }
}
