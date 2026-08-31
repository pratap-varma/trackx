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
            if (call.method == "updateWidget") {
                try {
                    val prefs = getSharedPreferences("TrackXWidgetPrefs", Context.MODE_PRIVATE)
                    val editor = prefs.edit()

                    val attendance = call.argument<String>("overallAttendance") ?: ""
                    val classesToday = call.argument<Int>("classesToday") ?: 0
                    val nextClassName = call.argument<String>("nextClassName") ?: ""
                    val nextClassTime = call.argument<String>("nextClassTime") ?: ""
                    val nextClassRoom = call.argument<String>("nextClassRoom") ?: ""
                    val alertMessage = call.argument<String>("alertMessage") ?: ""
                    val tasksPending = call.argument<Int>("tasksPending") ?: 0

                    editor.putString("overallAttendance", attendance)
                    editor.putInt("classesToday", classesToday)
                    editor.putString("nextClassName", nextClassName)
                    editor.putString("nextClassTime", nextClassTime)
                    editor.putString("nextClassRoom", nextClassRoom)
                    editor.putString("alertMessage", alertMessage)
                    editor.putInt("tasksPending", tasksPending)
                    editor.putLong("lastUpdatedAt", System.currentTimeMillis())
                    editor.apply()

                    // Broadcast widget update to all TrackXWidgetProvider instances
                    val appWidgetManager = AppWidgetManager.getInstance(this)
                    val thisAppWidget = ComponentName(this.packageName, TrackXWidgetProvider::class.java.name)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(thisAppWidget)

                    if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                        for (appWidgetId in appWidgetIds) {
                            TrackXWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)
                        }
                    }

                    result.success(true)
                } catch (e: Exception) {
                    result.error("WIDGET_UPDATE_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
