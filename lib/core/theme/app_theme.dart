import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color deepBlack = Color(0xFF0F0F0F);
  static const Color cardColor = Color(0xFF1E1E1E);
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
      background: deepBlack,
      error: errorRed,
      onPrimary: Colors.black, // Dark text on gold button
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(
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
      backgroundColor: deepBlack,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}
