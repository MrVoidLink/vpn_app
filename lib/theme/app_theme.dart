import 'package:flutter/material.dart';

/// رنگ‌های برند
const Color kNeonPurple = Color(0xFF6C63FF);
const Color kNeonCyan   = Color(0xFF00C2FF);

/// پس‌زمینه‌های تیره اسپلش
const Color kBgTopDark    = Color(0xFF0F1220);
const Color kBgBottomDark = Color(0xFF0A0D18);

@immutable
class BrandTheme extends ThemeExtension<BrandTheme> {
  final Gradient primaryGradient;
  final Gradient backgroundGradient;
  final Color glowPurple;
  final Color glowCyan;

  const BrandTheme({
    required this.primaryGradient,
    required this.backgroundGradient,
    required this.glowPurple,
    required this.glowCyan,
  });

  @override
  BrandTheme copyWith({
    Gradient? primaryGradient,
    Gradient? backgroundGradient,
    Color? glowPurple,
    Color? glowCyan,
  }) {
    return BrandTheme(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glowPurple: glowPurple ?? this.glowPurple,
      glowCyan: glowCyan ?? this.glowCyan,
    );
  }

  @override
  BrandTheme lerp(ThemeExtension<BrandTheme>? other, double t) {
    if (other is! BrandTheme) return this;
    return this;
  }
}

class AppTheme {
  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: kNeonPurple,
    onPrimary: Colors.white,
    secondary: kNeonCyan,
    onSecondary: Colors.black,
    error: Color(0xFFFF4D4F),
    onError: Colors.white,
    background: Color(0xFF0C0F1B),
    onBackground: Colors.white,
    surface: Color(0xFF121528),
    onSurface: Colors.white,
  );

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: kNeonPurple,
    onPrimary: Colors.white,
    secondary: kNeonCyan,
    onSecondary: Colors.black,
    error: Color(0xFFB00020),
    onError: Colors.white,
    background: Color(0xFFF6F8FF),
    onBackground: Color(0xFF1A1B25),
    surface: Colors.white,
    onSurface: Color(0xFF1A1B25),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: const Color(0xFF0E1120),
    fontFamily: 'Roboto',

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121528),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800),
      displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
      displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ).apply(bodyColor: Colors.white, displayColor: Colors.white),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStatePropertyAll(const Size(56, 48)),
        shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return Colors.white10;
          return _darkScheme.primary;
        }),
        foregroundColor: const MaterialStatePropertyAll(Colors.white),
        overlayColor: MaterialStatePropertyAll(kNeonCyan.withOpacity(0.12)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: const ButtonStyle(
        foregroundColor: MaterialStatePropertyAll(kNeonCyan),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStatePropertyAll(const Size(56, 48)),
        shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        side: const MaterialStatePropertyAll(
            BorderSide(color: kNeonCyan, width: 1.2)),
        foregroundColor: const MaterialStatePropertyAll(kNeonCyan),
        overlayColor: MaterialStatePropertyAll(kNeonCyan.withOpacity(0.08)),
      ),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF141835),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
    ),


    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF171B3A),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kNeonCyan, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF4D4F)),
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: kNeonCyan,
      linearTrackColor: Colors.white12,
    ),

    switchTheme: const SwitchThemeData(
      thumbColor: MaterialStatePropertyAll(kNeonCyan),
      trackColor: MaterialStatePropertyAll(Colors.white24),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF121528),
      surfaceTintColor: Colors.transparent,
      indicatorColor: kNeonCyan.withOpacity(0.15),
      labelTextStyle: const MaterialStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF141835),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
    ),


    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF141835),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),

    extensions: const [
      BrandTheme(
        primaryGradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [kNeonPurple, kNeonCyan],
        ),
        backgroundGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kBgTopDark, kBgBottomDark],
        ),
        glowPurple: Color(0x336C63FF),
        glowCyan: Color(0x3300C2FF),
      ),
    ],
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: const Color(0xFFF6F8FF),
    textTheme: const TextTheme().apply(
      bodyColor: Color(0xFF1A1B25),
      displayColor: Color(0xFF1A1B25),
    ),
    extensions: const [
      BrandTheme(
        primaryGradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [kNeonPurple, kNeonCyan],
        ),
        backgroundGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6F8FF), Color(0xFFEFF3FF)],
        ),
        glowPurple: Color(0x206C63FF),
        glowCyan: Color(0x2000C2FF),
      ),
    ],
  );
}
