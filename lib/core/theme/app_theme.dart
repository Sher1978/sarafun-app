import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color deepBlack = Color(0xFF0F0F0F);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color errorRed = Color(0xFFCF6679);

  static final ThemeData darkLuxury = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepBlack,
    primaryColor: primaryGold,
    colorScheme: const ColorScheme.dark(
      primary: primaryGold,
      secondary: primaryGold,
      surface: cardColor,
      error: errorRed,
      onPrimary: Colors.black, // Dark text on gold button
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    // cardTheme: CardTheme(
    //   color: cardColor,
    //   elevation: 0,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(16),
    //   ),
    // ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: primaryGold,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
      iconTheme: IconThemeData(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(80, 40),
      ),
    ),
  );

  // Compact UI Constants (60% smaller baseline)
  static const double compactCardWidth = 160.0;
  static const double compactCardHeight = 220.0;
  static const double compactImageHeight = 100.0;
}



class AppHaptics {
  /// Triggers a light impact (good for standard buttons)
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Triggers a medium impact (good for important actions)
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Triggers a selection click (good for tab changes)
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
}
