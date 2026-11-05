import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SideBColors {
  SideBColors._();
  static const graphite = Color(0xFF292A27);
  static const ivory = Color(0xFFEAE3D6);
  static const olive = Color(0xFF858C77);
  static const accent = Color(0xFFD4704C);
  static const paper = Color(0xFFF7F2E9);
  static const muted = Color(0xFF686861);
  static const border = Color(0x33292A27);
  static const error = Color(0xFFB5473F);
  static const success = Color(0xFF4D7057);
  static const skeleton = Color(0xFFDDD7CB);
}

class SideBTheme {
  SideBTheme._();
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: SideBColors.ivory,
    colorScheme: const ColorScheme.light(
      primary: SideBColors.accent,
      onPrimary: Colors.white,
      surface: SideBColors.paper,
      onSurface: SideBColors.graphite,
      outline: SideBColors.border,
      error: SideBColors.error,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
      displaySmall: GoogleFonts.instrumentSerif(
        fontSize: 40,
        height: .96,
        color: SideBColors.graphite,
      ),
      headlineMedium: GoogleFonts.instrumentSerif(
        fontSize: 32,
        height: 1,
        color: SideBColors.graphite,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: SideBColors.graphite,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        height: 1.5,
        color: SideBColors.graphite,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        height: 1.45,
        color: SideBColors.muted,
      ),
      labelMedium: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.25,
        color: SideBColors.muted,
      ),
    ),
    dividerTheme: const DividerThemeData(color: SideBColors.border, space: 1),
  );
}
