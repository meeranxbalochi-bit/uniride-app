import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Provides the singleton [AuthService] instance.
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

/// Stream of Firebase Auth state changes (User? stream).
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// The current user's Firestore profile, derived from [authServiceProvider].
final userProfileProvider = Provider<UserProfile?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.profile;
});

/// The current user's role string.
final userRoleProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider)?.role ?? 'student';
});

/// Whether the auth service is still loading.
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isLoading;
});

/// Whether the user is fully authenticated with a Firestore profile.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isAuthenticated;
});

/// Stream of all user profiles from Firestore (for Admin user management).
final allUsersProvider =
    StreamProvider<List<UserProfile>>((ref) {
  return FirestoreService.usersRef.snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
        .toList();
  });
});
