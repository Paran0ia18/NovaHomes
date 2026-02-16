import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/theme.dart';

class NovaPrimaryButton extends StatelessWidget {
  const NovaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.black,
    this.textColor = AppColors.background,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
          textStyle: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: GoogleFonts.lato(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (icon != null) ...<Widget>[
              const SizedBox(width: 10),
              Icon(icon, size: 24, color: AppColors.accent),
            ],
          ],
        ),
      ),
    );
  }
}
