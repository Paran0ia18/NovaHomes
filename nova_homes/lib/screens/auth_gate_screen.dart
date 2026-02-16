import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/theme.dart';
import 'main_shell_screen.dart';
import 'onboarding_screen.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key, AuthService? authService})
    : _authService = authService;

  final AuthService? _authService;

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return const OnboardingScreen();
    }
    final AuthService authService = _authService ?? AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CircularProgressIndicator(color: AppColors.black),
                  const SizedBox(height: 14),
                  Text(
                    'Loading NovaHomes...',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data == null) {
          return const OnboardingScreen();
        }
        return const MainShellScreen();
      },
    );
  }
}
