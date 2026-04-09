import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      developer.log('Teacher signed in: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Sign-in error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      developer.log('Unexpected sign-in error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      developer.log('New teacher registered: ${userCredential.user?.email}');
      
      // Set display name (optional)
      await userCredential.user?.updateProfile(displayName: email.split('@')[0]);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Registration error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      developer.log('Unexpected registration error: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      developer.log('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      developer.log('Password reset error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      developer.log('Unexpected password reset error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      developer.log('Teacher signed out');
    } catch (e) {
      developer.log('Sign-out error: $e');
      rethrow;
    }
  }

  // Get ID token for API calls
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      developer.log('Error getting ID token: $e');
      return null;
    }
  }
}
