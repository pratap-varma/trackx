import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/admin/data/repositories/admin_repository.dart';
import 'package:trackx/features/admin/domain/models/admin_models.dart';

enum AdminAuthStatus { initial, loading, authenticated, unauthenticated, error }

class AdminAuthState {
  final AdminAuthStatus status;
  final AdminUserSummary? admin;
  final String? errorMessage;

  const AdminAuthState({
    required this.status,
    this.admin,
    this.errorMessage,
  });

  factory AdminAuthState.initial() => const AdminAuthState(status: AdminAuthStatus.initial);
  factory AdminAuthState.loading() => const AdminAuthState(status: AdminAuthStatus.loading);
  factory AdminAuthState.authenticated(AdminUserSummary admin) => AdminAuthState(
        status: AdminAuthStatus.authenticated,
        admin: admin,
      );
  factory AdminAuthState.unauthenticated([String? error]) => AdminAuthState(
        status: AdminAuthStatus.unauthenticated,
        errorMessage: error,
      );
  factory AdminAuthState.error(String error) => AdminAuthState(
        status: AdminAuthStatus.error,
        errorMessage: error,
      );

  bool get isAuthenticated => status == AdminAuthStatus.authenticated;
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminRepository _repository;

  AdminAuthNotifier(this._repository) : super(AdminAuthState.initial()) {
    checkAdminAuth();
  }

  Future<void> checkAdminAuth() async {
    state = AdminAuthState.loading();
    try {
      final uid = _repository.currentAdminUid;
      if (uid == null) {
        state = AdminAuthState.unauthenticated();
        return;
      }

      final isAdmin = await _repository.verifyAdminStatus(uid);
      if (isAdmin) {
        state = AdminAuthState.authenticated(
          AdminUserSummary(
            uid: uid,
            name: 'Administrator',
            email: _repository.currentAdminEmail ?? 'admin@trackx.app',
            branch: 'Administration',
            semester: 0,
            createdTimestamp: 0,
          ),
        );
      } else {
        state = AdminAuthState.unauthenticated();
      }
    } catch (_) {
      state = AdminAuthState.unauthenticated();
    }
  }

  Future<bool> login(String email, String password) async {
    state = AdminAuthState.loading();
    try {
      final admin = await _repository.adminLogin(email, password);
      state = AdminAuthState.authenticated(admin);
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '');
      state = AdminAuthState.error(err);
      return false;
    }
  }

  Future<void> logout() async {
    state = AdminAuthState.loading();
    await _repository.adminLogout();
    state = AdminAuthState.unauthenticated();
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final adminAuthStateProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminAuthNotifier(repo);
});

final adminUsersFilterProvider = StateProvider<String>((ref) => 'All'); // 'All', 'Active', 'Suspended'
final adminUsersSearchProvider = StateProvider<String>((ref) => '');

final adminUsersListProvider = FutureProvider<List<AdminUserSummary>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final all = await repo.fetchAllUsers();
  final filter = ref.watch(adminUsersFilterProvider);
  final search = ref.watch(adminUsersSearchProvider).trim().toLowerCase();

  return all.where((u) {
    // Status filter
    if (filter == 'Active' && u.isSuspended) return false;
    if (filter == 'Suspended' && !u.isSuspended) return false;

    // Search query
    if (search.isNotEmpty) {
      final matchName = u.name.toLowerCase().contains(search);
      final matchEmail = u.email.toLowerCase().contains(search);
      final matchUid = u.uid.toLowerCase().contains(search);
      final matchBranch = u.branch.toLowerCase().contains(search);
      return matchName || matchEmail || matchUid || matchBranch;
    }

    return true;
  }).toList();
});

final adminAnalyticsOverviewProvider =
    FutureProvider<AdminAnalyticsOverview>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchAnalyticsOverview();
});

final adminActivityLogsProvider =
    FutureProvider<List<ActivityLogEntry>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchRecentActivityLogs(limit: 50);
});

final adminUserDetailProvider =
    FutureProvider.family<AdminUserDetail?, String>((ref, uid) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchUserDetail(uid);
});
