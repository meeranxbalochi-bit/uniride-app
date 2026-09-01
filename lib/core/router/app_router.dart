import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/pending_screen.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/driver/driver_dashboard.dart';
import '../../features/student/student_dashboard.dart';

/// Route path constants.
class AppRoutes {
  static const String login = '/login';
  static const String pending = '/pending';
  static const String admin = '/admin';
  static const String driver = '/driver';
  static const String student = '/student';
}

/// GoRouter provider with auth-based redirects.
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: false,
    refreshListenable: authService,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoading = authService.isLoading;
      final isAuthenticated = authService.isAuthenticated;
      final profile = authService.profile;
      final currentPath = state.matchedLocation;

      // While loading, don't redirect
      if (isLoading) return null;

      // Not authenticated → force login
      if (!isAuthenticated) {
        if (currentPath == AppRoutes.login) return null;
        return AppRoutes.login;
      }

      // Authenticated but on login page → redirect based on role
      if (currentPath == AppRoutes.login) {
        return _roleRoute(profile?.role);
      }

      // If on any route, make sure it matches their role
      // (prevent students from accessing /admin, etc.)
      final expectedRoute = _roleRoute(profile?.role);
      if (currentPath != expectedRoute &&
          currentPath != AppRoutes.pending) {
        return expectedRoute;
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.pending,
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.driver,
        builder: (context, state) => const DriverDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.student,
        builder: (context, state) => const StudentDashboardScreen(),
      ),
    ],
  );
});

/// Maps a user role string to its home route.
String _roleRoute(String? role) {
  switch (role) {
    case 'admin':
      return AppRoutes.admin;
    case 'driver':
      return AppRoutes.driver;
    case 'student':
      return AppRoutes.student;
    default:
      return AppRoutes.student;
  }
}
