import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetDataService {
  final SharedPreferences _prefs;

  WidgetDataService(this._prefs);

  static const String _widgetDataKey = 'px_home_widget_summary_data';

  Future<void> updateWidgetData({
    required double overallAttendance,
    required int classesToday,
    required String nextClassName,
    required String alertMessage,
  }) async {
    final Map<String, dynamic> data = {
      'overallAttendance': overallAttendance,
      'classesToday': classesToday,
      'nextClassName': nextClassName,
      'alertMessage': alertMessage,
      'lastUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _prefs.setString(_widgetDataKey, jsonEncode(data));
  }

  Map<String, dynamic> getWidgetData() {
    final raw = _prefs.getString(_widgetDataKey);
    if (raw == null) {
      return {
        'overallAttendance': 0.0,
        'classesToday': 0,
        'nextClassName': 'None',
        'alertMessage': 'No Alerts',
        'lastUpdatedAt': 0,
      };
    }
    return jsonDecode(raw);
  }
}
