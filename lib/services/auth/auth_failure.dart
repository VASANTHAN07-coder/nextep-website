import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

AuthFailure mapFirebaseAuthException(FirebaseAuthException exception) {
  switch (exception.code) {
    case 'user-not-found':
      return const AuthFailure(
          'user-not-found', 'No account found for this email.');
    case 'wrong-password':
    case 'invalid-credential':
      return const AuthFailure(
          'invalid-credential', 'Invalid email or password.');
    case 'email-already-in-use':
      return const AuthFailure(
          'email-already-in-use', 'Email is already registered.');
    case 'weak-password':
      return const AuthFailure(
          'weak-password', 'Password must be at least 6 characters.');
    case 'invalid-email':
      return const AuthFailure(
          'invalid-email', 'Please enter a valid email address.');
    case 'network-request-failed':
      return const AuthFailure('network-request-failed',
          'Network error. Check your connection and try again.');
    case 'operation-not-allowed':
      return const AuthFailure('operation-not-allowed',
          'This sign-in method is not enabled in Firebase.');
    default:
      return AuthFailure(exception.code,
          exception.message ?? 'Authentication failed. Please try again.');
  }
}

AuthFailure mapGenericAuthError(Object error) {
  if (error is AuthFailure) {
    return error;
  }

  if (error is PlatformException) {
    final String raw =
        '${error.code} ${error.message ?? ''} ${error.details ?? ''}'
            .toLowerCase();

    if (raw.contains('apiexception: 10') ||
        (error.code == 'sign_in_failed' && raw.contains('api'))) {
      return const AuthFailure(
        'google-sign-in-config',
        'Google Sign-In config error (ApiException:10). Add SHA-1 and SHA-256 for com.pathwise.app in Firebase, then download and replace google-services.json.',
      );
    }

    if (raw.contains('network')) {
      return const AuthFailure(
        'network-request-failed',
        'Network error. Check your connection and try again.',
      );
    }

    return AuthFailure(
      error.code,
      (error.message ?? 'Sign-in failed. Please try again.').trim(),
    );
  }

  if (error is FirebaseAuthException) {
    return mapFirebaseAuthException(error);
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return const AuthFailure(
          'permission-denied',
          'Permission denied. Check your Firebase rules.',
        );
      case 'unavailable':
        return const AuthFailure(
          'unavailable',
          'Service unavailable. Please try again in a moment.',
        );
      case 'network-request-failed':
        return const AuthFailure(
          'network-request-failed',
          'Network error. Check your connection and try again.',
        );
      default:
        return AuthFailure(
          error.code,
          error.message ?? 'Request failed. Please try again.',
        );
    }
  }

  final String text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.toLowerCase().contains('permission') &&
      text.toLowerCase().contains('caller')) {
    return const AuthFailure(
      'permission-denied',
      'Permission denied by Firestore rules. Allow authenticated users to read/write their own students/{uid} document.',
    );
  }

  if (text.isNotEmpty && text.toLowerCase() != 'exception') {
    return AuthFailure('unknown', text);
  }

  return const AuthFailure(
      'unknown', 'Something went wrong. Please try again.');
}
