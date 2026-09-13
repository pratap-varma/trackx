package com.example.trackx.trackx

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class WidgetRefreshReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        val isManual = intent?.getBooleanExtra("manual_refresh", false) == true
        performRefresh(context, showToast = isManual)
    }

    companion object {
        const val ACTION_REFRESH_WIDGETS = "com.example.trackx.ACTION_REFRESH_WIDGETS"

        fun performRefresh(context: Context, showToast: Boolean = false) {
            try {
                val prefs = context.getSharedPreferences("TrackXWidgetPrefs", Context.MODE_PRIVATE)

                // 1. Sync latest data from FlutterSharedPreferences if available
                try {
                    val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    var flutterDataStr = flutterPrefs.getString("flutter.px_home_widgets_data_v2", null)
                    if (flutterDataStr.isNullOrEmpty()) {
                        flutterDataStr = flutterPrefs.getString("px_home_widgets_data_v2", null)
                    }

                    if (!flutterDataStr.isNullOrEmpty()) {
                        val fData = JSONObject(flutterDataStr)
                        val editor = prefs.edit()

                        if (fData.has("overallAttendance")) editor.putString("overallAttendance", fData.optString("overallAttendance"))
                        if (fData.has("attendanceBadge")) editor.putString("attendanceBadge", fData.optString("attendanceBadge"))
                        if (fData.has("attendanceBunkInfo")) editor.putString("attendanceBunkInfo", fData.optString("attendanceBunkInfo"))
                        if (fData.has("attendanceTargetInfo")) editor.putString("attendanceTargetInfo", fData.optString("attendanceTargetInfo"))
                        if (fData.has("attendanceRatio")) editor.putString("attendanceRatio", fData.optString("attendanceRatio"))

                        if (fData.has("scheduleDay")) editor.putString("scheduleDay", fData.optString("scheduleDay"))
                        if (fData.has("scheduleBadge")) editor.putString("scheduleBadge", fData.optString("scheduleBadge"))
                        if (fData.has("nextClassMeta")) editor.putString("nextClassMeta", fData.optString("nextClassMeta"))
                        if (fData.has("nextClassName")) editor.putString("nextClassName", fData.optString("nextClassName"))
                        if (fData.has("nextClassRoom")) editor.putString("nextClassRoom", fData.optString("nextClassRoom"))
                        if (fData.has("scheduleSummary")) editor.putString("scheduleSummary", fData.optString("scheduleSummary"))
                        if (fData.has("classesToday")) editor.putInt("classesToday", fData.optInt("classesToday"))
                        if (fData.has("scheduleSlotsJson")) editor.putString("scheduleSlotsJson", fData.optString("scheduleSlotsJson"))

                        if (fData.has("examsHeader")) editor.putString("examsHeader", fData.optString("examsHeader"))
                        if (fData.has("examsBadge")) editor.putString("examsBadge", fData.optString("examsBadge"))
                        if (fData.has("nextExamMeta")) editor.putString("nextExamMeta", fData.optString("nextExamMeta"))
                        if (fData.has("nextExamTitle")) editor.putString("nextExamTitle", fData.optString("nextExamTitle"))
                        if (fData.has("nextExamDateTime")) editor.putString("nextExamDateTime", fData.optString("nextExamDateTime"))
                        if (fData.has("examsSummary")) editor.putString("examsSummary", fData.optString("examsSummary"))
                        if (fData.has("upcomingExamsCount")) editor.putInt("upcomingExamsCount", fData.optInt("upcomingExamsCount"))
                        if (fData.has("examsSlotsJson")) editor.putString("examsSlotsJson", fData.optString("examsSlotsJson"))

                        if (fData.has("themeMode")) editor.putString("themeMode", fData.optString("themeMode"))
                        if (fData.has("isDark")) editor.putBoolean("isDark", fData.optBoolean("isDark"))
                        if (fData.has("accentColor")) editor.putString("accentColor", fData.optString("accentColor"))

                        editor.commit()
                    }
                } catch (_: Exception) {}

                // 2. Recalculate schedule slots status based on real current time
                val slotsJson = prefs.getString("scheduleSlotsJson", null)
                if (!slotsJson.isNullOrEmpty()) {
                    try {
                        val jsonArray = JSONArray(slotsJson)
                        val calendar = Calendar.getInstance()
                        val currentMinutes = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
                        var updated = false

                        for (i in 0 until jsonArray.length()) {
                            val obj = jsonArray.getJSONObject(i)
                            val startMin = obj.optInt("startMinutes", -1)
                            val endMin = obj.optInt("endMinutes", -1)

                            if (startMin >= 0 && endMin >= 0) {
                                val newStatus = when {
                                    currentMinutes in startMin..endMin -> "NOW"
                                    startMin > currentMinutes -> "UPCOMING"
                                    else -> "DONE"
                                }
                                if (obj.optString("status") != newStatus) {
                                    obj.put("status", newStatus)
                                    updated = true
                                }
                            }
                        }

                        if (updated) {
                            prefs.edit().putString("scheduleSlotsJson", jsonArray.toString()).commit()
                        }
                    } catch (_: Exception) {}
                }

                // 3. Update timestamp
                prefs.edit().putLong("lastUpdatedAt", System.currentTimeMillis()).commit()

                // 4. Broadcast updates to all widgets
                val appWidgetManager = AppWidgetManager.getInstance(context)

                // 4a. Attendance Widget
                val attComponent = ComponentName(context.packageName, AttendanceWidgetProvider::class.java.name)
                val attIds = appWidgetManager.getAppWidgetIds(attComponent)
                if (attIds != null && attIds.isNotEmpty()) {
                    for (id in attIds) {
                        AttendanceWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                    }
                }

                // 4b. Schedule Widget
                val schComponent = ComponentName(context.packageName, ScheduleWidgetProvider::class.java.name)
                val schIds = appWidgetManager.getAppWidgetIds(schComponent)
                if (schIds != null && schIds.isNotEmpty()) {
                    for (id in schIds) {
                        ScheduleWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                    }
                }

                // 4c. Exams Widget
                val exComponent = ComponentName(context.packageName, ExamsWidgetProvider::class.java.name)
                val exIds = appWidgetManager.getAppWidgetIds(exComponent)
                if (exIds != null && exIds.isNotEmpty()) {
                    for (id in exIds) {
                        ExamsWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                    }
                }

                // 4d. TrackX Combined Widget
                val mainComponent = ComponentName(context.packageName, TrackXWidgetProvider::class.java.name)
                val mainIds = appWidgetManager.getAppWidgetIds(mainComponent)
                if (mainIds != null && mainIds.isNotEmpty()) {
                    for (id in mainIds) {
                        TrackXWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                    }
                }

                // 5. Schedule the next periodic alarm
                val intervalMinutes = prefs.getLong("refreshIntervalMinutes", 30L)
                scheduleNextAlarm(context, intervalMinutes)

                // 6. User feedback on manual refresh
                if (showToast) {
                    Toast.makeText(context, "TrackX widgets refreshed \u21BB", Toast.LENGTH_SHORT).show()
                }
            } catch (_: Exception) {}
        }

        fun scheduleNextAlarm(context: Context, intervalMinutes: Long) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val safeMinutes = if (intervalMinutes > 0) intervalMinutes else 30L
                val intervalMs = safeMinutes * 60 * 1000L
                val triggerAt = System.currentTimeMillis() + intervalMs

                val intent = Intent(context, WidgetRefreshReceiver::class.java).apply {
                    action = ACTION_REFRESH_WIDGETS
                    putExtra("manual_refresh", false)
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    9001,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC, triggerAt, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC, triggerAt, pendingIntent)
                }
            } catch (_: Exception) {}
        }
    }
}
