import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    fontFamily: 'SpaceGrotesk',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'InstrumentSerif',
        fontSize: 40,
        height: .96,
        color: SideBColors.graphite,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'InstrumentSerif',
        fontSize: 32,
        height: 1,
        color: SideBColors.graphite,
      ),
      titleLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 18,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: SideBColors.graphite,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 16,
        height: 1.5,
        color: SideBColors.graphite,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        height: 1.45,
        color: SideBColors.muted,
      ),
      labelMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.25,
        color: SideBColors.muted,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SideBColors.ivory,
      foregroundColor: SideBColors.graphite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: SideBColors.graphite,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .6,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SideBColors.graphite,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: SideBColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SideBColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SideBColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SideBColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SideBColors.olive, width: 1.5),
      ),
      errorMaxLines: 3,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SideBColors.graphite,
      contentTextStyle: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 14,
        color: SideBColors.paper,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: SideBColors.olive,
      strokeWidth: 2.5,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: SideBColors.olive,
      selectionColor: Color(0x44858C77),
      selectionHandleColor: SideBColors.olive,
    ),
    dividerTheme: const DividerThemeData(color: SideBColors.border, space: 1),
  );
}
