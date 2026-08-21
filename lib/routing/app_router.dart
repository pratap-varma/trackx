import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trackx/features/authentication/data/auth_repository.dart';
import 'package:trackx/features/authentication/domain/auth_state.dart';
import 'package:trackx/routing/main_shell.dart';

// Screens
import 'package:trackx/features/onboarding/presentation/splash_screen.dart';
import 'package:trackx/features/authentication/presentation/login_screen.dart';
import 'package:trackx/features/authentication/presentation/register_screen.dart';
import 'package:trackx/features/authentication/presentation/forgot_password_screen.dart';
import 'package:trackx/features/onboarding/presentation/onboarding_screen.dart';
import 'package:trackx/features/subjects/presentation/subject_detail_screen.dart';
import 'package:trackx/features/semesters/presentation/semester_manage_screen.dart';
import 'package:trackx/features/cgpa_screen.dart';
import 'package:trackx/features/notes/presentation/screens/notes_screen.dart';
import 'package:trackx/features/timetable/presentation/screens/timetable_screen.dart';
import 'package:trackx/features/profile/presentation/backup_screen.dart';
import 'package:trackx/features/ai_assistant/presentation/screens/ai_chat_screen.dart';
import 'package:trackx/features/attendance/presentation/screens/classroom_mapping_screen.dart';
import 'package:trackx/features/profile/presentation/feedback_screen.dart';
import 'package:trackx/features/timetable_import/presentation/screens/timetable_import_screen.dart';
import 'package:trackx/features/study_timer/presentation/screens/focus_timer_screen.dart';
import 'package:trackx/features/profile/presentation/semester_comparison_screen.dart';
import 'package:trackx/features/integrations/presentation/screens/reconciliation_screen.dart';
import 'package:trackx/features/integrations/presentation/screens/qr_scanner_screen.dart';
import 'package:trackx/features/profile/presentation/devices_screen.dart';

// Stage 16 Screens
import 'package:trackx/features/profile/presentation/academics_hub_screen.dart';
import 'package:trackx/features/profile/presentation/programme_manage_screen.dart';
import 'package:trackx/features/subjects/presentation/dependency_manage_screen.dart';
import 'package:trackx/features/profile/presentation/graduation_progress_screen.dart';
import 'package:trackx/features/subjects/presentation/course_planning_screen.dart';
import 'package:trackx/features/semesters/presentation/future_semester_planner_screen.dart';
import 'package:trackx/features/semesters/presentation/scenario_comparison_screen.dart';
import 'package:trackx/features/subjects/presentation/topic_tracking_screen.dart';
import 'package:trackx/features/planner/presentation/screens/exam_prep_detail_screen.dart';
import 'package:trackx/features/notes/presentation/screens/resource_library_screen.dart';
import 'package:trackx/features/profile/presentation/global_search_screen.dart';

import 'package:flutter/foundation.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authRepositoryProvider, (_, _) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const MainShell()),
      GoRoute(
        path: '/subject-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return SubjectDetailScreen(subjectId: id);
        },
      ),
      GoRoute(
        path: '/semester-manage',
        builder: (context, state) => const SemesterManageScreen(),
      ),
      GoRoute(path: '/notes', builder: (context, state) => const NotesScreen()),
      GoRoute(path: '/cgpa', builder: (context, state) => const CgpaScreen()),
      GoRoute(
        path: '/timetable',
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(path: '/ai', builder: (context, state) => const AIChatScreen()),
      GoRoute(
        path: '/classrooms',
        builder: (context, state) => const ClassroomMappingScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/import-timetable',
        builder: (context, state) => const TimetableImportScreen(),
      ),
      GoRoute(
        path: '/focus-timer',
        builder: (context, state) => const FocusTimerScreen(),
      ),
      GoRoute(
        path: '/comparison',
        builder: (context, state) => const SemesterComparisonScreen(),
      ),
      GoRoute(
        path: '/reconciliation',
        builder: (context, state) => const ReconciliationScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/devices',
        builder: (context, state) => const DevicesScreen(),
      ),
      // Stage 16 routes
      GoRoute(
        path: '/academics',
        builder: (context, state) => const AcademicsHubScreen(),
      ),
      GoRoute(
        path: '/programmes',
        builder: (context, state) => const ProgrammeManageScreen(),
      ),
      GoRoute(
        path: '/dependencies',
        builder: (context, state) => const DependencyManageScreen(),
      ),
      GoRoute(
        path: '/graduation',
        builder: (context, state) => const GraduationProgressScreen(),
      ),
      GoRoute(
        path: '/courses',
        builder: (context, state) => const CoursePlanningScreen(),
      ),
      GoRoute(
        path: '/scenarios',
        builder: (context, state) => const FutureSemesterPlannerScreen(),
      ),
      GoRoute(
        path: '/scenarios-compare',
        builder: (context, state) => const ScenarioComparisonScreen(),
      ),
      GoRoute(
        path: '/topics',
        builder: (context, state) => const TopicTrackingScreen(),
      ),
      GoRoute(
        path: '/exam-prep',
        builder: (context, state) => const ExamPrepDetailScreen(),
      ),
      GoRoute(
        path: '/resources',
        builder: (context, state) => const ResourceLibraryScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authRepositoryProvider);
      final status = authState.status;
      final onboarding = authState.userProfile?.onboardingCompleted ?? false;

      final goingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';
      final goingToSplash = state.matchedLocation == '/splash';

      if (status == AuthStatus.loading) {
        // If already on auth pages, stay on auth page while loading
        if (goingToAuth) return null;
        return goingToSplash ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated || status == AuthStatus.error) {
        return goingToAuth ? null : '/login';
      }

      if (status == AuthStatus.authenticated) {
        if (!onboarding) {
          return state.matchedLocation == '/onboarding' ? null : '/onboarding';
        }
        if (goingToAuth || goingToSplash) {
          return '/';
        }
      }
      return null;
    },
  );
});
