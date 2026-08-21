import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/theme/app_theme.dart';

final aiPrivacyProvider =
    StateNotifierProvider<AiPrivacyNotifier, Map<String, bool>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return AiPrivacyNotifier(prefs);
    });

class AiPrivacyNotifier extends StateNotifier<Map<String, bool>> {
  final SharedPreferences _prefs;

  AiPrivacyNotifier(this._prefs)
    : super({
        'attendance': true,
        'timetable': true,
        'tasks': true,
        'assignments': true,
        'exams': true,
        'cgpa': true,
        'notes': false, // Excluded by default
      }) {
    _load();
  }

  void _load() {
    state = {
      'attendance': _prefs.getBool('ai_consent_attendance') ?? true,
      'timetable': _prefs.getBool('ai_consent_timetable') ?? true,
      'tasks': _prefs.getBool('ai_consent_tasks') ?? true,
      'assignments': _prefs.getBool('ai_consent_assignments') ?? true,
      'exams': _prefs.getBool('ai_consent_exams') ?? true,
      'cgpa': _prefs.getBool('ai_consent_cgpa') ?? true,
      'notes': _prefs.getBool('ai_consent_notes') ?? false,
    };
  }

  Future<void> toggle(String key) async {
    final updated = !state[key]!;
    state = {...state, key: updated};
    await _prefs.setBool('ai_consent_$key', updated);
  }

  Future<void> clearHistory() async {
    // Emulates deleting conversation logs from storage
    await _prefs.remove('ai_conversation_history');
  }
}

class AiPrivacyScreen extends ConsumerWidget {
  const AiPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(aiPrivacyProvider);
    final notifier = ref.read(aiPrivacyProvider.notifier);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'AI Consent & Privacy',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Manage what information is shared with cloud AI models (e.g., Gemini, OpenAI). Offline insights are always calculated locally.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            GlassContainer(
              child: Column(
                children: consent.keys.map((key) {
                  return SwitchListTile(
                    title: Text(
                      key.substring(0, 1).toUpperCase() + key.substring(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      key == 'notes'
                          ? 'Share raw text details of study notes (Disabled by default).'
                          : 'Enable context-sharing for $key.',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                    value: consent[key]!,
                    activeThumbColor: AppTheme.accentPurple,
                    onChanged: (val) => notifier.toggle(key),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI History Management',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permanently delete chat transcripts, study planner drafts, and cached AI recommendations.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  GlassPrimaryButton(
                    text: 'Delete AI History',
                    onPressed: () async {
                      await notifier.clearHistory();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('AI history deleted successfully!'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
