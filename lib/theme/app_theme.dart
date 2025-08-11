import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00FF88); // سبز نئونی
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFF6C63FF);
  static const Color errorColor = Color(0xFFFF4D4D);

  static const String fontFamily = 'Roboto';

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primaryColor,
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
      ),
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: primaryColor, secondary: accentColor, error: errorColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF151515),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),

  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLight,
    primaryColor: primaryColor,
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundLight,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold,
      ),
      centerTitle: true,
    ),
    colorScheme: const ColorScheme.light().copyWith(
      primary: primaryColor, secondary: accentColor, error: errorColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor, foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),
  );
}
