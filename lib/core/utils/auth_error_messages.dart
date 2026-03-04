import 'package:firebase_auth/firebase_auth.dart';

/// User-friendly messages for Firebase Auth errors.
class AuthErrorMessages {
  AuthErrorMessages._();

  static String forException(FirebaseAuthException e) {
    switch (e.code) {
      case 'CONFIGURATION_NOT_FOUND':
        return 'Email/Password sign-in is not enabled for this app. '
            'Ask the developer to enable it in Firebase Console: '
            'Authentication → Sign-in method → Email/Password → Enable.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Sign in or use another email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled. Contact the developer.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      default:
        return e.message ?? e.code;
    }
  }
}
