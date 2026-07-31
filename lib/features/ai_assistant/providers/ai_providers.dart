import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/semesters/data/semester_repository.dart';
import 'package:trackx/features/ai_advisor/domain/models/ai_models.dart';
import 'package:trackx/features/ai_assistant/data/repositories/ai_conversation_repository.dart';
import 'package:trackx/features/ai_assistant/data/repositories/ai_action_history_repository.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/ai_assistant/domain/models/ai_usage.dart';

final aiConversationRepositoryProvider = Provider<AiConversationRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiConversationRepository(prefs);
});

final aiActionHistoryRepositoryProvider = Provider<AiActionHistoryRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiActionHistoryRepository(prefs);
});

// Settings & Consent flags StateNotifier
class AiSettingsState {
  final bool enableAi;
  final bool saveHistory;
  final bool showConsentPreview;
  final Map<String, bool> consentFlags;
  final String activeConversationId;
  final String provider; // Auto, Gemini, OpenAI, Offline

  AiSettingsState({
    required this.enableAi,
    required this.saveHistory,
    required this.showConsentPreview,
    required this.consentFlags,
    required this.activeConversationId,
    required this.provider,
  });

  AiSettingsState copyWith({
    bool? enableAi,
    bool? saveHistory,
    bool? showConsentPreview,
    Map<String, bool>? consentFlags,
    String? activeConversationId,
    String? provider,
  }) {
    return AiSettingsState(
      enableAi: enableAi ?? this.enableAi,
      saveHistory: saveHistory ?? this.saveHistory,
      showConsentPreview: showConsentPreview ?? this.showConsentPreview,
      consentFlags: consentFlags ?? this.consentFlags,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      provider: provider ?? this.provider,
    );
  }
}

class AiSettingsNotifier extends StateNotifier<AiSettingsState> {
  final SharedPreferences _prefs;

  AiSettingsNotifier(this._prefs)
      : super(AiSettingsState(
          enableAi: _prefs.getBool('ai_setting_enabled') ?? true,
          saveHistory: _prefs.getBool('ai_setting_save_history') ?? true,
          showConsentPreview: _prefs.getBool('ai_setting_show_preview') ?? true,
          provider: _prefs.getString('ai_setting_provider') ?? 'Auto',
          activeConversationId: 'default',
          consentFlags: {
            'attendance': _prefs.getBool('ai_consent_attendance') ?? true,
            'timetable': _prefs.getBool('ai_consent_timetable') ?? true,
            'tasks': _prefs.getBool('ai_consent_tasks') ?? true,
            'assignments': _prefs.getBool('ai_consent_assignments') ?? true,
            'exams': _prefs.getBool('ai_consent_exams') ?? true,
            'cgpa': _prefs.getBool('ai_consent_cgpa') ?? true,
            'notes': _prefs.getBool('ai_consent_notes') ?? false,
          },
        ));

  Future<void> toggleEnableAi(bool val) async {
    state = state.copyWith(enableAi: val);
    await _prefs.setBool('ai_setting_enabled', val);
  }

  Future<void> toggleSaveHistory(bool val) async {
    state = state.copyWith(saveHistory: val);
    await _prefs.setBool('ai_setting_save_history', val);
  }

  Future<void> toggleShowPreview(bool val) async {
    state = state.copyWith(showConsentPreview: val);
    await _prefs.setBool('ai_setting_show_preview', val);
  }

  Future<void> setProvider(String provider) async {
    state = state.copyWith(provider: provider);
    await _prefs.setString('ai_setting_provider', provider);
  }

  Future<void> toggleConsentFlag(String key) async {
    final flags = Map<String, bool>.from(state.consentFlags);
    flags[key] = !(flags[key] ?? false);
    state = state.copyWith(consentFlags: flags);
    await _prefs.setBool('ai_consent_$key', flags[key]!);
  }

  void setActiveConversationId(String id) {
    state = state.copyWith(activeConversationId: id);
  }
}

final aiSettingsProvider = StateNotifierProvider<AiSettingsNotifier, AiSettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiSettingsNotifier(prefs);
});

// AI Usage Tracker StateNotifier
class AiUsageNotifier extends StateNotifier<AiUsageSummary> {
  final SharedPreferences _prefs;

  AiUsageNotifier(this._prefs)
      : super(AiUsageSummary(
          requestsToday: _prefs.getInt('ai_usage_requests_today') ?? 0,
          requestsThisMonth: _prefs.getInt('ai_usage_requests_month') ?? 0,
          maxDailyRequests: 20,
          maxMonthlyRequests: 300,
          offlineFallbacksCount: _prefs.getInt('ai_usage_offline_count') ?? 0,
        )) {
    _resetIfNeeded();
  }

  void _resetIfNeeded() {
    final lastRequestStr = _prefs.getString('ai_usage_last_request_date');
    if (lastRequestStr != null) {
      final lastDate = DateTime.parse(lastRequestStr);
      final now = DateTime.now();
      if (lastDate.day != now.day || lastDate.month != now.month || lastDate.year != now.year) {
        state = AiUsageSummary(
          requestsToday: 0,
          requestsThisMonth: lastDate.month != now.month ? 0 : state.requestsThisMonth,
          maxDailyRequests: state.maxDailyRequests,
          maxMonthlyRequests: state.maxMonthlyRequests,
          offlineFallbacksCount: state.offlineFallbacksCount,
        );
        _prefs.setInt('ai_usage_requests_today', 0);
        if (lastDate.month != now.month) {
          _prefs.setInt('ai_usage_requests_month', 0);
        }
      }
    }
  }

  Future<void> incrementRequests() async {
    _resetIfNeeded();
    final updated = AiUsageSummary(
      requestsToday: state.requestsToday + 1,
      requestsThisMonth: state.requestsThisMonth + 1,
      maxDailyRequests: state.maxDailyRequests,
      maxMonthlyRequests: state.maxMonthlyRequests,
      offlineFallbacksCount: state.offlineFallbacksCount,
    );
    state = updated;
    await _prefs.setInt('ai_usage_requests_today', updated.requestsToday);
    await _prefs.setInt('ai_usage_requests_month', updated.requestsThisMonth);
    await _prefs.setString('ai_usage_last_request_date', DateTime.now().toIso8601String());
  }

  Future<void> incrementOfflineFallback() async {
    final updated = AiUsageSummary(
      requestsToday: state.requestsToday,
      requestsThisMonth: state.requestsThisMonth,
      maxDailyRequests: state.maxDailyRequests,
      maxMonthlyRequests: state.maxMonthlyRequests,
      offlineFallbacksCount: state.offlineFallbacksCount + 1,
    );
    state = updated;
    await _prefs.setInt('ai_usage_offline_count', updated.offlineFallbacksCount);
  }
}

final aiUsageProvider = StateNotifierProvider<AiUsageNotifier, AiUsageSummary>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AiUsageNotifier(prefs);
});
