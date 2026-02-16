import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color accent = Color(0xFFD4AF37);
  static const Color border = Color(0xFFF2F2F2);
  static const Color cream = Color(0xFFF9F4E8);
  static const Color black = Color(0xFF000000);
}

class AppTheme {
  const AppTheme._();

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(20),
  );

  static const BoxShadow subtleShadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  static TextStyle get displayTitle => GoogleFonts.playfairDisplay(
    fontSize: 44,
    fontWeight: FontWeight.bold,
    height: 1.05,
    color: AppColors.textPrimary,
  );

  static TextStyle get heading => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySecondary => GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static ThemeData get lightTheme {
    final TextTheme textTheme = TextTheme(
      displayLarge: displayTitle,
      headlineMedium: heading,
      bodyLarge: body,
      bodyMedium: bodySecondary,
      labelLarge: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.black,
        secondary: AppColors.accent,
        surface: AppColors.background,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        hintStyle: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: const BorderSide(color: AppColors.black, width: 1.2),
        ),
      ),
    );
  }
}
