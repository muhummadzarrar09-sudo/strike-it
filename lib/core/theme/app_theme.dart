import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// STREAK IT — DARK BRUTALIST DESIGN SYSTEM
///
/// Philosophy:
///   "Color gets its power from scarcity."
///   #FF4D1C is reserved for streak numbers, active states, and CTAs ONLY.
///   Everything else: black, white, gray.
///
///   No shadows. No gradients. No rounded corners. Bold typography.
///   Raw borders. High contrast. Deliberate negative space.
/// ═══════════════════════════════════════════════════════════════════════

class StreakItTheme {
  StreakItTheme._();

  static const Color accent = Color(0xFFFF4D1C);
  static const Color black = Color(0xFF000000);
  static const Color nearBlack = Color(0xFF0A0A0A);
  static const Color deepCharcoal = Color(0xFF141414);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color midGray = Color(0xFF4A4A4A);
  static const Color mutedGray = Color(0xFF6B6B6B);
  static const Color lightGray = Color(0xFF9B9B9B);
  static const Color offWhite = Color(0xFFD6D6D6);
  static const Color nearWhite = Color(0xFFF2F2F2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFCA8A04);
  static const Color error = Color(0xFFDC2626);

  static const List<Color> heatmapColors = [
    Color(0xFF1A1A1A),
    Color(0xFF3D1307),
    Color(0xFF6B1F0A),
    Color(0xFFA82E0E),
    Color(0xFFFF4D1C),
  ];

  static TextTheme get textTheme => GoogleFonts.spaceGroteskTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 96, fontWeight: FontWeight.w900, letterSpacing: -3, height: 1.0, color: nearWhite),
          displayMedium: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, letterSpacing: -2, height: 1.05, color: nearWhite),
          displaySmall: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.1, color: nearWhite),
          headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.15, color: white),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2, color: white),
          headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.25, height: 1.25, color: white),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0, height: 1.3, color: offWhite),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.35, color: offWhite),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.4, color: lightGray),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15, height: 1.5, color: offWhite),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.5, color: offWhite),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.5, color: mutedGray),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5, height: 1.4, color: offWhite),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.25, height: 1.4, color: mutedGray),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, height: 1.4, color: mutedGray),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: black,
        colorScheme: const ColorScheme.dark(surface: black, onSurface: nearWhite, primary: accent, onPrimary: white, secondary: darkGray, onSecondary: offWhite, error: error, onError: white),
        textTheme: textTheme,
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
        appBarTheme: const AppBarTheme(backgroundColor: black, foregroundColor: nearWhite, elevation: 0, scrolledUnderElevation: 0, centerTitle: false, surfaceTintColor: Colors.transparent),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: nearBlack, selectedItemColor: accent, unselectedItemColor: mutedGray, elevation: 0, type: BottomNavigationBarType.fixed),
        cardTheme: CardThemeData(color: deepCharcoal, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0), side: const BorderSide(color: darkGray, width: 1)), margin: EdgeInsets.zero),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: deepCharcoal, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(0), borderSide: const BorderSide(color: darkGray, width: 1)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(0), borderSide: const BorderSide(color: darkGray, width: 1)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(0), borderSide: const BorderSide(color: accent, width: 2)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(0), borderSide: const BorderSide(color: error, width: 1)), hintStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: midGray)),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16))),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: offWhite, side: const BorderSide(color: darkGray, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16))),
        dividerTheme: const DividerThemeData(color: darkGray, thickness: 1, space: 0),
        dialogTheme: DialogThemeData(backgroundColor: nearBlack, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0), side: const BorderSide(color: darkGray, width: 1))),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: nearBlack, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(0)), side: BorderSide(color: darkGray, width: 1))),
        snackBarTheme: SnackBarThemeData(backgroundColor: deepCharcoal, contentTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: offWhite), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0), side: const BorderSide(color: darkGray, width: 1)), behavior: SnackBarBehavior.floating),
      );
}