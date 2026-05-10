import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:guidex/models/register_student_request.dart';
import 'package:guidex/models/student_profile.dart';
import 'package:guidex/services/auth/auth_failure.dart';
import 'package:guidex/services/auth/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _injectedAuth = auth,
        _injectedFirestore = firestore,
        _injectedGoogleSignIn = googleSignIn;

  final FirebaseAuth? _injectedAuth;
  final FirebaseFirestore? _injectedFirestore;
  final GoogleSignIn? _injectedGoogleSignIn;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _injectedFirestore ?? FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn => _injectedGoogleSignIn ?? GoogleSignIn(scopes: <String>['email']);

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('students');

  @override
  Future<StudentProfile> registerWithEmail(
      RegisterStudentRequest request) async {
    _validateRegisterRequest(request);

    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: request.email.trim(),
        password: request.password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          'register-failed',
          'Unable to create account. Please try again.',
        );
      }

      final StudentProfile profile = StudentProfile(
        uid: user.uid,
        name: request.name.trim(),
        email: request.email.trim(),
        cutoff: request.cutoff,
        category: _normalizedCategory(request.category),
        preferredCourse: _normalizedPreferredCourse(request.preferredCourse),
      );

      try {
        await _students.doc(user.uid).set(profile.toJson());
      } on FirebaseException catch (exception) {
        final failure = _mapFirestoreException(
          exception,
          fallbackMessage: 'Failed to save profile to Firestore.',
        );

        // Keep onboarding moving even when Firestore rules are restrictive.
        if (failure.code == 'permission-denied') {
          return profile;
        }
        throw failure;
      }

      return profile;
    } on FirebaseAuthException catch (exception) {
      throw mapFirebaseAuthException(exception);
    } on FirebaseException catch (exception) {
      throw _mapFirestoreException(
        exception,
        fallbackMessage: 'Failed to save profile to Firestore.',
      );
    } catch (exception) {
      throw mapGenericAuthError(exception);
    }
  }

  @override
  Future<StudentProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _validateEmail(email);
    _validatePassword(password);

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          'login-failed',
          'Unable to login. Please try again.',
        );
      }

      try {
        return await _fetchProfileByUid(user.uid);
      } on AuthFailure catch (failure) {
        if (failure.code == 'permission-denied') {
          return _buildLocalProfile(user, preferredName: user.displayName);
        }
        rethrow;
      }
    } on FirebaseAuthException catch (exception) {
      throw mapFirebaseAuthException(exception);
    } catch (exception) {
      throw mapGenericAuthError(exception);
    }
  }

  @override
  Future<StudentProfile> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthFailure(
            'google-cancelled', 'Google sign-in was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw const AuthFailure(
          'google-token-missing',
          'Unable to read Google ID token.',
        );
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) {
        throw const AuthFailure(
            'google-login-failed', 'Google sign-in failed.');
      }

      try {
        return await _getOrCreateProfile(user,
            preferredName: googleUser.displayName);
      } on AuthFailure catch (failure) {
        if (failure.code == 'permission-denied') {
          return _buildLocalProfile(user,
              preferredName: googleUser.displayName);
        }
        rethrow;
      }
    } on FirebaseAuthException catch (exception) {
      throw mapFirebaseAuthException(exception);
    } on FirebaseException catch (exception) {
      throw AuthFailure(
        exception.code,
        exception.message ?? 'Google sign-in failed. Please try again.',
      );
    } catch (exception) {
      throw mapGenericAuthError(exception);
    }
  }

  @override
  Future<StudentProfile> signInWithApple() async {
    final bool isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final bool isApplePlatform = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (!isAndroid && !isApplePlatform) {
      throw const AuthFailure(
        'apple-not-supported',
        'Apple sign-in is not supported on this device.',
      );
    }

    try {
      final AppleAuthProvider provider = AppleAuthProvider();
      provider.addScope('email');
      provider.addScope('name');

      final UserCredential credential =
          await _auth.signInWithProvider(provider);
      final User? user = credential.user;
      if (user == null) {
        throw const AuthFailure('apple-login-failed', 'Apple sign-in failed.');
      }

      try {
        return await _getOrCreateProfile(user, preferredName: user.displayName);
      } on AuthFailure catch (failure) {
        if (failure.code == 'permission-denied') {
          return _buildLocalProfile(user, preferredName: user.displayName);
        }
        rethrow;
      }
    } on UnimplementedError {
      throw const AuthFailure(
        'apple-not-supported',
        'Apple sign-in is not available in this build.',
      );
    } on UnsupportedError {
      throw const AuthFailure(
        'apple-not-supported',
        'Apple sign-in is not supported on this Android configuration.',
      );
    } on FirebaseAuthException catch (exception) {
      throw mapFirebaseAuthException(exception);
    } on FirebaseException catch (exception) {
      throw AuthFailure(
        exception.code,
        exception.message ?? 'Apple sign-in failed. Please try again.',
      );
    } catch (exception) {
      throw mapGenericAuthError(exception);
    }
  }

  @override
  Future<StudentProfile?> restoreSession() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      return await _fetchProfileByUid(user.uid);
    } on AuthFailure catch (failure) {
      if (failure.code == 'permission-denied') {
        return _buildLocalProfile(user, preferredName: user.displayName);
      }
      return _getOrCreateProfile(user, preferredName: user.displayName);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google session may not exist for email/password users.
    }
  }

  Future<StudentProfile> _fetchProfileByUid(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _students.doc(uid).get();
      final Map<String, dynamic>? data = doc.data();

      if (!doc.exists || data == null) {
        throw const AuthFailure(
          'profile-not-found',
          'Profile not found. Please complete registration first.',
        );
      }

      return StudentProfile.fromJson(data);
    } on FirebaseException catch (exception) {
      throw _mapFirestoreException(
        exception,
        fallbackMessage: 'Failed to fetch profile data.',
      );
    }
  }

  Future<StudentProfile> _getOrCreateProfile(
    User user, {
    String? preferredName,
  }) async {
    final DocumentReference<Map<String, dynamic>> docRef =
        _students.doc(user.uid);

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        return StudentProfile.fromJson(doc.data()!);
      }

      final StudentProfile profile = StudentProfile(
        uid: user.uid,
        name: (preferredName ?? user.displayName ?? 'Student').trim(),
        email: (user.email ?? '').trim(),
        cutoff: 0,
        category: _normalizedCategory(null),
        preferredCourse: _normalizedPreferredCourse(null),
      );

      await docRef.set(profile.toJson());
      return profile;
    } on FirebaseException catch (exception) {
      throw _mapFirestoreException(
        exception,
        fallbackMessage: 'Failed to prepare profile data.',
      );
    }
  }

  StudentProfile _buildLocalProfile(
    User user, {
    String? preferredName,
  }) {
    return StudentProfile(
      uid: user.uid,
      name: (preferredName ?? user.displayName ?? 'Student').trim(),
      email: (user.email ?? '').trim(),
      cutoff: 0,
      category: _normalizedCategory(null),
      preferredCourse: _normalizedPreferredCourse(null),
    );
  }

  AuthFailure _mapFirestoreException(
    FirebaseException exception, {
    required String fallbackMessage,
  }) {
    if (exception.code == 'permission-denied') {
      return const AuthFailure(
        'permission-denied',
        'Permission denied by Firestore rules. Allow authenticated users to read/write their own students/{uid} document.',
      );
    }

    if (exception.code == 'unavailable') {
      return const AuthFailure(
        'unavailable',
        'Firestore is unavailable. Please try again in a moment.',
      );
    }

    return AuthFailure(
      exception.code,
      exception.message ?? fallbackMessage,
    );
  }

  void _validateRegisterRequest(RegisterStudentRequest request) {
    if (request.name.trim().isEmpty) {
      throw const AuthFailure('invalid-name', 'Name is required.');
    }
    _validateEmail(request.email);
    _validatePassword(request.password);

    if (request.cutoff < 0 || request.cutoff > 200) {
      throw const AuthFailure(
        'invalid-cutoff',
        'Cutoff must be between 0 and 200.',
      );
    }
  }

  String _normalizedCategory(String? category) {
    final value = (category ?? '').trim();
    return value.isEmpty ? 'Not Provided' : value;
  }

  String _normalizedPreferredCourse(String? preferredCourse) {
    final value = (preferredCourse ?? '').trim();
    return value.isEmpty ? 'Not Provided' : value;
  }

  void _validateEmail(String email) {
    final String value = email.trim();
    if (value.isEmpty) {
      throw const AuthFailure('invalid-email', 'Email is required.');
    }

    const String pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(pattern).hasMatch(value)) {
      throw const AuthFailure('invalid-email', 'Please enter a valid email.');
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw const AuthFailure('invalid-password', 'Password is required.');
    }
    if (password.length < 6) {
      throw const AuthFailure(
        'weak-password',
        'Password must be at least 6 characters.',
      );
    }
  }
}
