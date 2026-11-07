import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register User
  Future<User?> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && displayName.trim().isNotEmpty) {
        await result.user?.updateDisplayName(displayName.trim());
        await result.user?.reload();
      }

      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration Firebase Auth Error: ${e.code} - ${e.message}');
      throw _getReadableAuthError(e);
    } catch (e) {
      debugPrint('Registration Error: $e');
      rethrow;
    }
  }

  // Login User
  Future<User?> login(
    String email,
    String password,
  ) async {
    try {
      UserCredential result =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login Firebase Auth Error: ${e.code} - ${e.message}');
      throw _getReadableAuthError(e);
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  // Logout User
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;

  // Authentication State
  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  // Helper for friendly error messages
  static String _getReadableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
