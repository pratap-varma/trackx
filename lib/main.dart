import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/routing/app_router.dart';
import 'package:trackx/theme/app_theme.dart';
import 'package:trackx/core/services/app_lock_service.dart';
import 'package:trackx/core/presentation/widgets/app_lock_screen.dart';
import 'package:trackx/features/notifications/services/daily_digest_service.dart';
import 'package:trackx/features/notifications/services/exam_notification_service.dart';
import 'package:trackx/features/planner/providers/productivity_provider.dart';
import 'package:trackx/features/timetable/data/services/notification_service.dart';
import 'package:trackx/core/services/db_migration_service.dart';
import 'package:trackx/core/services/hive_db_service.dart';
import 'package:trackx/core/services/sync_service.dart';
import 'package:trackx/core/services/widget_data_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

  final hiveDb = HiveDbService();
  try {
    await hiveDb.init();
    final migration = DbMigrationService(prefs, hiveDb);
    await migration.migrate();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        hiveDbServiceProvider.overrideWithValue(hiveDb),
      ],
      child: const TrackXApp(),
    ),
  );
}

class TrackXApp extends ConsumerStatefulWidget {
  const TrackXApp({super.key});

  @override
  ConsumerState<TrackXApp> createState() => _TrackXAppState();
}

class _TrackXAppState extends ConsumerState<TrackXApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize Daily Morning Digest, Class reminders & Exam Notifications with fresh local data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(notificationServiceProvider).requestPermissions();
      } catch (_) {}
      try {
        await ref.read(examNotificationServiceProvider).initialize();
      } catch (_) {}
      ref.read(dailyDigestSettingsProvider);
      ref.read(examsProvider);
      try {
        await ref.read(widgetDataServiceProvider).syncWithAppData(ref);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      ref.read(appLockProvider.notifier).lock();
      try {
        ref.read(widgetDataServiceProvider).syncWithAppData(ref);
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      try {
        ref.read(widgetDataServiceProvider).syncWithAppData(ref);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final accentColor = ref.watch(accentColorProvider);
    final themeMode = ref.watch(themeModeProvider);
    final lockState = ref.watch(appLockProvider);

    return MaterialApp.router(
      title: 'TrackX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(Brightness.light, accentColor),
      darkTheme: AppTheme.buildTheme(Brightness.dark, accentColor),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (lockState.isLocked) {
          return const AppLockScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
