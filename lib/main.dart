import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/routing/app_router.dart';
import 'package:trackx/theme/app_theme.dart';
import 'package:trackx/core/services/app_lock_service.dart';
import 'package:trackx/core/presentation/widgets/app_lock_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final accentColor = ref.watch(accentColorProvider);
    final lockState = ref.watch(appLockProvider);

    return MaterialApp.router(
      title: 'TrackX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(Brightness.light, accentColor),
      darkTheme: AppTheme.buildTheme(Brightness.dark, accentColor),
      themeMode: ThemeMode.dark,
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
