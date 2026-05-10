import 'package:guidex/models/register_student_request.dart';
import 'package:guidex/models/student_profile.dart';

abstract class AuthService {
  Future<StudentProfile> registerWithEmail(RegisterStudentRequest request);

  Future<StudentProfile> signInWithEmail({
    required String email,
    required String password,
  });

  Future<StudentProfile> signInWithGoogle();

  Future<StudentProfile> signInWithApple();

  Future<StudentProfile?> restoreSession();

  Future<void> signOut();
}
