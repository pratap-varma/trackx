package com.example.trackx.trackx

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val WIDGET_CHANNEL = "com.example.trackx/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidgets" || call.method == "updateWidget") {
                try {
                    val prefs = getSharedPreferences("TrackXWidgetPrefs", Context.MODE_PRIVATE)
                    val editor = prefs.edit()

                    // 1. Attendance Data
                    val attendance = call.argument<String>("overallAttendance") ?: "--%"
                    val attendanceBadge = call.argument<String>("attendanceBadge") ?: "ON TRACK"
                    val attendanceBunkInfo = call.argument<String>("attendanceBunkInfo") ?: "Safe to Bunk: -- classes"
                    val attendanceTargetInfo = call.argument<String>("attendanceTargetInfo") ?: "Target: 75%"
                    val attendanceRatio = call.argument<String>("attendanceRatio") ?: "-- / -- Conducted"

                    editor.putString("overallAttendance", attendance)
                    editor.putString("attendanceBadge", attendanceBadge)
                    editor.putString("attendanceBunkInfo", attendanceBunkInfo)
                    editor.putString("attendanceTargetInfo", attendanceTargetInfo)
                    editor.putString("attendanceRatio", attendanceRatio)

                    // 2. Schedule Data
                    val scheduleDay = call.argument<String>("scheduleDay") ?: "DAILY SCHEDULE"
                    val scheduleBadge = call.argument<String>("scheduleBadge") ?: "TODAY"
                    val nextClassMeta = call.argument<String>("nextClassMeta") ?: "TODAY'S CLASSES"
                    val nextClassName = call.argument<String>("nextClassName") ?: "No classes scheduled today"
                    val nextClassRoom = call.argument<String>("nextClassRoom") ?: ""
                    val scheduleSummary = call.argument<String>("scheduleSummary") ?: "Tap to view full timetable"
                    val classesToday = call.argument<Int>("classesToday") ?: 0
                    val scheduleSlotsJson = call.argument<String>("scheduleSlotsJson") ?: "[]"

                    editor.putString("scheduleDay", scheduleDay)
                    editor.putString("scheduleBadge", scheduleBadge)
                    editor.putString("nextClassMeta", nextClassMeta)
                    editor.putString("nextClassName", nextClassName)
                    editor.putString("nextClassRoom", nextClassRoom)
                    editor.putString("scheduleSummary", scheduleSummary)
                    editor.putInt("classesToday", classesToday)
                    editor.putString("scheduleSlotsJson", scheduleSlotsJson)

                    // 3. Exams & Events Data
                    val examsHeader = call.argument<String>("examsHeader") ?: "EXAMS & EVENTS"
                    val examsBadge = call.argument<String>("examsBadge") ?: "SCHEDULED"
                    val nextExamMeta = call.argument<String>("nextExamMeta") ?: "UPCOMING EXAM"
                    val nextExamTitle = call.argument<String>("nextExamTitle") ?: "No upcoming exams scheduled"
                    val nextExamDateTime = call.argument<String>("nextExamDateTime") ?: "Add exams in Planner to track"
                    val examsSummary = call.argument<String>("examsSummary") ?: "0 upcoming exams • 0 tasks pending"
                    val upcomingExamsCount = call.argument<Int>("upcomingExamsCount") ?: 0
                    val examsSlotsJson = call.argument<String>("examsSlotsJson") ?: "[]"

                    editor.putString("examsHeader", examsHeader)
                    editor.putString("examsBadge", examsBadge)
                    editor.putString("nextExamMeta", nextExamMeta)
                    editor.putString("nextExamTitle", nextExamTitle)
                    editor.putString("nextExamDateTime", nextExamDateTime)
                    editor.putString("examsSummary", examsSummary)
                    editor.putInt("upcomingExamsCount", upcomingExamsCount)
                    editor.putString("examsSlotsJson", examsSlotsJson)

                    // 4. Theme & Appearance
                    val themeMode = call.argument<String>("themeMode") ?: "dark"
                    val isDark = call.argument<Boolean>("isDark") ?: true
                    val accentColor = call.argument<String>("accentColor") ?: "#5B5FEF"

                    editor.putString("themeMode", themeMode)
                    editor.putBoolean("isDark", isDark)
                    editor.putString("accentColor", accentColor)

                    editor.putLong("lastUpdatedAt", System.currentTimeMillis())
                    editor.commit()

                    // Broadcast updates to all AppWidget Providers
                    val appWidgetManager = AppWidgetManager.getInstance(this)

                    // 1. Attendance Widget
                    val attComponent = ComponentName(this.packageName, AttendanceWidgetProvider::class.java.name)
                    val attIds = appWidgetManager.getAppWidgetIds(attComponent)
                    if (attIds != null && attIds.isNotEmpty()) {
                        for (id in attIds) {
                            AttendanceWidgetProvider.updateAppWidget(this, appWidgetManager, id)
                        }
                    }

                    // 2. Schedule Widget
                    val schComponent = ComponentName(this.packageName, ScheduleWidgetProvider::class.java.name)
                    val schIds = appWidgetManager.getAppWidgetIds(schComponent)
                    if (schIds != null && schIds.isNotEmpty()) {
                        for (id in schIds) {
                            ScheduleWidgetProvider.updateAppWidget(this, appWidgetManager, id)
                        }
                    }

                    // 3. Exams Widget
                    val exComponent = ComponentName(this.packageName, ExamsWidgetProvider::class.java.name)
                    val exIds = appWidgetManager.getAppWidgetIds(exComponent)
                    if (exIds != null && exIds.isNotEmpty()) {
                        for (id in exIds) {
                            ExamsWidgetProvider.updateAppWidget(this, appWidgetManager, id)
                        }
                    }

                    // 4. TrackX Combined Widget
                    val mainComponent = ComponentName(this.packageName, TrackXWidgetProvider::class.java.name)
                    val mainIds = appWidgetManager.getAppWidgetIds(mainComponent)
                    if (mainIds != null && mainIds.isNotEmpty()) {
                        for (id in mainIds) {
                            TrackXWidgetProvider.updateAppWidget(this, appWidgetManager, id)
                        }
                    }

                    // 5. Auto-schedule periodic background refresh
                    val intervalMinutes = call.argument<Int>("refreshIntervalMinutes")?.toLong() ?: 30L
                    editor.putLong("refreshIntervalMinutes", intervalMinutes)
                    editor.commit()
                    WidgetRefreshReceiver.scheduleNextAlarm(this, intervalMinutes)

                    result.success(true)
                } catch (e: Exception) {
                    result.error("WIDGET_UPDATE_ERROR", e.localizedMessage, null)
                }
            } else if (call.method == "setRefreshInterval") {
                try {
                    val minutes = (call.argument<Int>("intervalMinutes") ?: 30).toLong()
                    val prefs = getSharedPreferences("TrackXWidgetPrefs", Context.MODE_PRIVATE)
                    prefs.edit().putLong("refreshIntervalMinutes", minutes).apply()
                    WidgetRefreshReceiver.scheduleNextAlarm(this, minutes)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INTERVAL_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
