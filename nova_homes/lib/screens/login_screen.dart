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
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                  'Welcome back',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Sign in to access your exclusive properties',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
              Text(
                'Email Address',
                style: GoogleFonts.lato(
                  color: const Color(0xFF22304A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.lato(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(hintText: 'name@example.com'),
              ),
              const SizedBox(height: 26),
              Text(
                'Password',
                style: GoogleFonts.lato(
                  color: const Color(0xFF22304A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.lato(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '........',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.lato(
                      color: const Color(0xFF667085),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              NovaPrimaryButton(
                label: _isLoading ? 'Loading...' : 'Log In',
                onPressed: _isLoading ? () {} : _loginWithEmail,
              ),
              const SizedBox(height: 28),
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
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  NovaSocialButton(
                    label: 'Google',
                    icon: const FaIcon(
                      FontAwesomeIcons.google,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    onTap: _isLoading ? () {} : _loginWithGoogle,
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
                      onTap: _isLoading ? () {} : _loginWithApple,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<SignUpScreen>(
                        builder: (_) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: 'Don\'t have an account? ',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF667085),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: 'Sign up',
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

  Future<void> _loginWithEmail() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }
    await _runAuthAction(() async {
      await _authService.signInWithEmail(email: email, password: password);
    });
  }

  Future<void> _loginWithGoogle() async {
    await _runAuthAction(() async {
      await _authService.signInWithGoogle();
    });
  }

  Future<void> _loginWithApple() async {
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
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
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
        return error.message ?? 'Authentication failed.';
    }
  }
}
