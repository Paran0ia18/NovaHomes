import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/nova_primary_button.dart';
import '../widgets/nova_social_button.dart';
import 'auth_gate_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _error;
  bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 8),
              Center(
                child: Icon(
                  Icons.home_outlined,
                  color: AppColors.textPrimary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: Text(
                  'Create account',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Join NovaHomes to unlock luxury stays worldwide',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...<Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF8B4B4)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: const Color(0xFFB42318),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _buildLabel('Full Name'),
              const SizedBox(height: 10),
              _buildTextField(
                hintText: 'Tom Smith',
                controller: _nameController,
              ),
              const SizedBox(height: 18),
              _buildLabel('Email Address'),
              const SizedBox(height: 10),
              _buildTextField(
                hintText: 'name@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              _buildLabel('Password'),
              const SizedBox(height: 10),
              _buildPasswordField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onToggle: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 18),
              _buildLabel('Confirm Password'),
              const SizedBox(height: 10),
              _buildPasswordField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                onToggle: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
              const SizedBox(height: 22),
              NovaPrimaryButton(
                label: _isLoading ? 'Loading...' : 'Sign Up',
                onPressed: _isLoading ? () {} : _signUpWithEmail,
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Divider(thickness: 1, color: Color(0xFFE4E7EC)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or continue with',
                      style: GoogleFonts.lato(
                        color: const Color(0xFF667085),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(thickness: 1, color: Color(0xFFE4E7EC)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  NovaSocialButton(
                    label: 'Google',
                    icon: const FaIcon(
                      FontAwesomeIcons.google,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    onTap: _isLoading ? () {} : _signUpWithGoogle,
                  ),
                  if (_isApplePlatform) ...<Widget>[
                    const SizedBox(width: 14),
                    NovaSocialButton(
                      label: 'Apple',
                      icon: const FaIcon(
                        FontAwesomeIcons.apple,
                        size: 21,
                        color: AppColors.textPrimary,
                      ),
                      onTap: _isLoading ? () {} : _signUpWithApple,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<LoginScreen>(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: 'Already have an account? ',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF667085),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: 'Log in',
                          style: GoogleFonts.lato(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.lato(
        color: const Color(0xFF22304A),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.lato(
        fontSize: 17,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(hintText: hintText),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.lato(
        fontSize: 17,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: '........',
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _signUpWithEmail() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirm = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Please complete all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must have at least 6 characters.');
      return;
    }

    await _runAuthAction(() async {
      await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
    });
  }

  Future<void> _signUpWithGoogle() async {
    await _runAuthAction(() async {
      await _authService.signInWithGoogle();
    });
  }

  Future<void> _signUpWithApple() async {
    await _runAuthAction(() async {
      await _authService.signInWithApple();
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<AuthGateScreen>(
          builder: (_) => const AuthGateScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _messageFromAuthException(error));
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _messageFromAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'aborted-by-user':
        return 'Sign-in cancelled.';
      case 'google-missing-id-token':
        return 'Google not configured yet. Add SHA-1/SHA-256 in Firebase and re-download google-services.json.';
      case 'google-sign-in-failed':
        return error.message ?? 'Google Sign-In failed.';
      case 'apple-not-supported':
        return 'Apple Sign-In is only available on iOS/macOS.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method.';
      default:
        return error.message ?? 'Registration failed.';
    }
  }
}
