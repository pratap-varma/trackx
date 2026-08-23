import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/routing/nav_provider.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/floating_dock.dart';

// Screens
import 'package:trackx/features/dashboard/presentation/dashboard_screen.dart';
import 'package:trackx/features/attendance/presentation/attendance_screen.dart';
import 'package:trackx/features/planner/presentation/screens/planner_screen.dart';
import 'package:trackx/features/ai_assistant/presentation/screens/ai_chat_screen.dart';
import 'package:trackx/features/profile/presentation/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(navIndexProvider));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navIndexProvider);


    final dockItems = const [
      DockItem(icon: Icons.home_rounded, label: 'Home'),
      DockItem(icon: Icons.assignment_outlined, label: 'Attendance'),
      DockItem(icon: Icons.calendar_today_rounded, label: 'Planner'),
      DockItem(icon: Icons.smart_toy_outlined, label: 'AI'),
      DockItem(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    final screens = const [
      DashboardScreen(),
      AttendanceScreen(),
      PlannerScreen(),
      AIChatScreen(),
      ProfileScreen(),
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Screen Contents
            Positioned.fill(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  ref.read(navIndexProvider.notifier).state = index;
                },
                children: screens,
              ),
            ),

            // Bottom Navigation Dock
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingDock(
                currentIndex: currentIndex,
                items: dockItems,
                onTabSelected: (index) {
                  ref.read(navIndexProvider.notifier).state = index;
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
