import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/routing/app_router.dart';
import 'package:trackx/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

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
    final accentColor = ref.watch(accentColorProvider);

    return MaterialApp.router(
      title: 'TrackX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(Brightness.light, accentColor),
      darkTheme: AppTheme.buildTheme(Brightness.dark, accentColor),
      themeMode: ThemeMode.dark, // Default to Luminous Intelligence Dark
      routerConfig: router,
    );
  }
}
