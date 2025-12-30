// lib/features/auth/logic/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInAnonymously() async {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Optional: Update the user's display name immediately after signup
    if (userCredential.user != null) {
      await userCredential.user!.updateDisplayName(name);
    }

    return userCredential;
  }

  Future<void> signOut() => _auth.signOut();

  // ---------------------------------------------------------
  // ✅ ADDED THESE 3 METHODS TO FIX YOUR ERRORS
  // ---------------------------------------------------------

  /// 1. Sends the verification email to the logged-in user
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// 2. Reloads user data from server (crucial for checking verification status)
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// 3. Triggers the "Forgot Password" email flow
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
