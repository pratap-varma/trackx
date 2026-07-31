import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/routing/app_router.dart';
import 'package:trackx/theme/app_theme.dart';

import 'package:trackx/core/utils/sample_data_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  // Load mock data if database is unpopulated
  try {
    await SampleDataLoader.loadSampleData(prefs);
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TrackXApp(),
    ),
  );
}

class TrackXApp extends ConsumerWidget {
  const TrackXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TrackX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to Dark glass VisionOS look
      routerConfig: router,
    );
  }
}
