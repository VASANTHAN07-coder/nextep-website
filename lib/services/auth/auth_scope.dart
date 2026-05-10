import 'package:guidex/services/auth/auth_controller.dart';
import 'package:guidex/services/auth/firebase_auth_service.dart';

class AuthScope {
  AuthScope._();

  static final AuthController controller =
      AuthController(FirebaseAuthService());
}
