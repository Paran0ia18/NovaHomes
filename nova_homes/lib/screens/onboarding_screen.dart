import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';
import '../widgets/nova_primary_button.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const String _heroImageUrl =
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1600&q=80';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.network(
            _heroImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) {
              return Container(color: const Color(0xFF4C6378));
            },
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x33000000),
                  Color(0x6E000000),
                  Color(0x9C000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  RichText(
                    text: TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: 'Find your dream\n',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: AppColors.background,
                            height: 1.05,
                          ),
                        ),
                        TextSpan(
                          text: 'holiday home',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Luxury villas and premium apartments worldwide.',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.background.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 34),
                  NovaPrimaryButton(
                    label: 'Get Started',
                    icon: Icons.arrow_forward_rounded,
                    backgroundColor: AppColors.background,
                    textColor: AppColors.black,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<SignUpScreen>(
                          builder: (_) => const SignUpScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
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
                                color: AppColors.background,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: 'Log in',
                              style: GoogleFonts.lato(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
