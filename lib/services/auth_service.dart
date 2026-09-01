import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/app_constants.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

/// Handles Google Sign-In, Firestore user profile provisioning,
/// and the Super Admin auto-bootstrap for [AppConstants.superAdminEmail].
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _profile != null;
  bool get isSuperAdmin =>
      _profile?.email.toLowerCase().trim() ==
      AppConstants.superAdminEmail.toLowerCase().trim();

  AuthService() {
    _initAuthState();
  }

  /// Listen to Firebase Auth state changes and load/create Firestore profile.
  void _initAuthState() {
    _auth.authStateChanges().listen((firebaseUser) async {
      _user = firebaseUser;
      if (firebaseUser != null) {
        try {
          _profile = await _processUserProfile(firebaseUser);
          _error = null;
        } catch (e) {
          debugPrint('Error processing user profile: $e');
          _error = 'Failed to load profile. Please try again.';
        }
      } else {
        _profile = null;
        _error = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Core bootstrap logic:
  /// 1. If user email == superAdminEmail and no profile exists → create as Admin.
  /// 2. If user email == superAdminEmail and profile exists with non-admin role → elevate to Admin.
  /// 3. For all other new users → create with 'student' role.
  Future<UserProfile> _processUserProfile(User firebaseUser) async {
    final email = firebaseUser.email?.toLowerCase().trim() ?? '';
    final isTargetAdmin =
        email == AppConstants.superAdminEmail.toLowerCase().trim();

    final userDoc = await FirestoreService.usersRef
        .doc(firebaseUser.uid)
        .get();

    if (!userDoc.exists) {
      // ── New user: auto-provision ──
      final newProfile = UserProfile(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ??
            (isTargetAdmin ? 'Super Admin' : 'Campus User'),
        photoURL: firebaseUser.photoURL,
        role: isTargetAdmin ? 'admin' : 'student',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await FirestoreService.usersRef
          .doc(firebaseUser.uid)
          .set(newProfile.toMap());
      return newProfile;
    } else {
      // ── Existing user: load and optionally elevate ──
      var existing =
          UserProfile.fromMap(firebaseUser.uid, userDoc.data()!);
      if (isTargetAdmin && existing.role != 'admin') {
        existing = existing.copyWith(role: 'admin');
        await FirestoreService.usersRef
            .doc(firebaseUser.uid)
            .update({'role': 'admin'});
      }
      return existing;
    }
  }

  /// Initiates Google Sign-In popup and processes the credential.
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        _isLoading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        _profile = await _processUserProfile(userCredential.user!);
      }
    } catch (e) {
      debugPrint('Google SSO Error: $e');
      _error = 'Sign-in failed. Please check your connection and try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the student's enrolled bus and stop for tracking.
  Future<void> updateStudentBus(String? busId,
      {String? stopId, String? stopName}) async {
    if (_profile == null || _user == null) return;
    _profile = _profile!.copyWith(
      studentBusId: busId,
      studentStopId: stopId,
      studentStopName: stopName,
    );
    await FirestoreService.usersRef.doc(_user!.uid).update({
      'studentBusId': busId,
      'studentStopId': stopId,
      'studentStopName': stopName,
    });
    notifyListeners();
  }

  /// Signs out the current user from both Google and Firebase.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
    _user = null;
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
