import 'package:flutter/foundation.dart';
import 'package:guidex/models/register_student_request.dart';
import 'package:guidex/models/student_profile.dart';
import 'package:guidex/services/auth/auth_failure.dart';
import 'package:guidex/services/auth/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;

  bool isLoading = false;
  String? errorMessage;
  StudentProfile? currentUser;

  Future<bool> restoreSession() async {
    _startLoading();
    try {
      currentUser = await _authService.restoreSession();
      return currentUser != null;
    } catch (error) {
      errorMessage = _toMessage(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> registerWithEmail(RegisterStudentRequest request) async {
    _startLoading();
    try {
      currentUser = await _authService.registerWithEmail(request);
      errorMessage = null;
      return true;
    } catch (error) {
      errorMessage = _toMessage(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      currentUser = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      errorMessage = null;
      return true;
    } catch (error) {
      errorMessage = _toMessage(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> signInWithGoogle() async {
    _startLoading();
    try {
      currentUser = await _authService.signInWithGoogle();
      errorMessage = null;
      return true;
    } catch (error) {
      errorMessage = _toMessage(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> signInWithApple() async {
    _startLoading();
    try {
      currentUser = await _authService.signInWithApple();
      errorMessage = null;
      return true;
    } catch (error) {
      errorMessage = _toMessage(error);
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<void> signOut() async {
    _startLoading();
    try {
      await _authService.signOut();
      currentUser = null;
      errorMessage = null;
    } catch (error) {
      errorMessage = _toMessage(error);
    } finally {
      _stopLoading();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _startLoading() {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    isLoading = false;
    notifyListeners();
  }

  String _toMessage(Object error) {
    return mapGenericAuthError(error).message;
  }
}
