import 'package:flutter/material.dart';
import 'package:guidex/app_routes.dart';
import 'package:guidex/models/register_student_request.dart';
import 'package:guidex/services/auth/auth_scope.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthScope.controller;
  bool _isPasswordVisible = false;
  bool _isAgreeWithTerms = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {
        _inlineError = _authController.errorMessage;
      });
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithEmail() async {
    if (!_isAgreeWithTerms) {
      _showError('Please agree to the Terms & Condition.');
      return;
    }

    final RegisterStudentRequest request = RegisterStudentRequest(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      cutoff: 0,
      category: 'Not Provided',
      preferredCourse: 'Not Provided',
    );

    final bool success = await _authController.registerWithEmail(request);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.userCategory,
        (route) => false,
      );
      return;
    }

    _showError(_authController.errorMessage ?? 'Registration failed.');
  }

  Future<void> _signInWithGoogle() async {
    final bool success = await _authController.signInWithGoogle();

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.userCategory,
        (route) => false,
      );
      return;
    }

    _showError(_authController.errorMessage ?? 'Google sign-in failed.');
  }

  Future<void> _signInWithApple() async {
    final bool success = await _authController.signInWithApple();

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.userCategory,
        (route) => false,
      );
      return;
    }

    _showError(_authController.errorMessage ?? 'Apple sign-in failed.');
  }

  void _showError(String message) {
    setState(() {
      _inlineError = message;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = _authController.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                // Top blue Circle
                Positioned(
                  top: -150,
                  left: -50,
                  right: -50,
                  child: Container(
                    height: 400,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 94, 194, 237),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 25),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Let’s build your success path ! ',
                              style: TextStyle(
                                fontSize: 12,
                                // fontWeight: FontWeight.w400,
                                color: Colors.grey[800],
                              ),
                            ),

                            const SizedBox(height: 88),
                            // Name Field
                            _buildInputField(
                              hint: 'Enter your Name',
                              controller: _nameController,
                            ),
                            const SizedBox(height: 20),
                            // Email Field
                            _buildInputField(
                              hint: 'Enter your Email',
                              controller: _emailController,
                            ),
                            const SizedBox(height: 20),
                            // Password Field
                            _buildInputField(
                              hint: 'Enter your Password',
                              controller: _passwordController,
                              isPassword: true,
                              isPasswordVisible: _isPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            // Agree with Terms and Condition
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _isAgreeWithTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _isAgreeWithTerms = value ?? false;
                                    });
                                  },
                                  activeColor: const Color.fromARGB(
                                    255,
                                    94,
                                    194,
                                    237,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Agree with ',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {},
                                      child: const Text(
                                        'Terms & Condition',
                                        style: TextStyle(
                                          color: Color.fromARGB(
                                            255,
                                            51,
                                            156,
                                            201,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_inlineError != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _inlineError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),
                            // Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    isLoading ? null : _registerWithEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    94,
                                    194,
                                    237,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.black87,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Or ',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            //  const SizedBox(height: 30),
                            // Bottom Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  Icons.apple,
                                  Colors.black,
                                  onTap: isLoading ? null : _signInWithApple,
                                ),
                                const SizedBox(width: 20),
                                _buildSocialButton(
                                  Icons.g_mobiledata_rounded,
                                  Colors.red,
                                  isGoogle: true,
                                  onTap: isLoading ? null : _signInWithGoogle,
                                ),
                                const SizedBox(width: 20),
                                _buildSocialButton(
                                  Icons.facebook,
                                  Colors.blue[800]!,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Social Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 5, 173, 245),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    // required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   label,
        //   style: const TextStyle(
        //     fontSize: 14,
        //     fontWeight: FontWeight.w500,
        //     color: Colors.black87,
        //   ),
        // ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !(isPasswordVisible ?? false),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isPasswordVisible ?? false)
                          ? Icons.visibility
                          : Icons.visibility_off_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    IconData icon,
    Color color, {
    bool isGoogle = false,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(icon, color: color, size: isGoogle ? 40 : 24),
          ),
        ),
      ),
    );
  }
}
