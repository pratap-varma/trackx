# Stage 17 Migration Details

TrackX Stage 17 extends local SharedPreferences configurations to support settings and data models introduced for the AI Assistant.

## Database Additions
- Added `px_ai_conversations_list` key for active thread listings.
- Added `px_ai_action_history_list` key for suggested and confirmed action audit logs.
- Added `ai_setting_enabled`, `ai_setting_save_history`, `ai_setting_show_preview`, and `ai_setting_provider` keys for settings.

All settings default to safe options (AI enabled, Save history enabled, Context preview on, Provider set to Auto). Backwards compatibility with Stage 16 is fully preserved.
