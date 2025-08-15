// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

/// --- ثابت‌های نئون در صورت نیاز سایر فایل‌ها ---
const Color kNeonPurple = Color(0xFF6C63FF);
const Color kNeonCyan   = Color(0xFF00C2FF);

/// پالت رنگ‌ها (مشکی/طوسی/بنفش)
class AppColors {
  // Core purple
  static const Color primary = Color(0xFF8A2BE2); // Electric Purple
  static const Color primaryDark = Color(0xFF6A0DAD); // Deeper Purple
  static const Color secondary = Color(0xFFA64DFF); // Accent Purple
  static const Color tertiary = Color(0xFF7C83FD);  // Violet-Blue accent

  // Dark neutrals
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkOutline = Color(0xFF2A2A2A);

  // Light neutrals
  static const Color lightBg = Color(0xFFF7F7F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFFE6E6EB);

  // Text
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textPrimaryLight = Color(0xFF0F0F14);
  static const Color textSecondaryLight = Color(0xFF5A5A66);

  // Feedback
  static const Color error = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
}

/// ThemeExtension برای رنگ‌ها و گرادیانت‌های برند
@immutable
class BrandTheme extends ThemeExtension<BrandTheme> {
  final LinearGradient primaryGradient;
  final LinearGradient backgroundGradient;
  final Color neonPurple;
  final Color neonCyan;

  const BrandTheme({
    required this.primaryGradient,
    required this.backgroundGradient,
    required this.neonPurple,
    required this.neonCyan,
  });

  @override
  BrandTheme copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? backgroundGradient,
    Color? neonPurple,
    Color? neonCyan,
  }) {
    return BrandTheme(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      neonPurple: neonPurple ?? this.neonPurple,
      neonCyan: neonCyan ?? this.neonCyan,
    );
  }

  @override
  BrandTheme lerp(ThemeExtension<BrandTheme>? other, double t) {
    if (other is! BrandTheme) return this;
    return BrandTheme(
      primaryGradient:
      LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      backgroundGradient:
      LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      neonPurple: Color.lerp(neonPurple, other.neonPurple, t)!,
      neonCyan: Color.lerp(neonCyan, other.neonCyan, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get dark => _buildDarkTheme();
  static ThemeData get light => _buildLightTheme();

  // ---- DARK THEME ----
  static ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      background: AppColors.darkBg,
      onBackground: AppColors.textPrimaryDark,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textPrimaryDark,
      surfaceVariant: const Color(0xFF232323), // فقط برای سازگاری
      outline: AppColors.darkOutline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.lightSurface,
      onInverseSurface: AppColors.textPrimaryLight,
      inversePrimary: AppColors.primaryDark,
    );

    // ThemeExtension برند
    final brand = const BrandTheme(
      primaryGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryDark, AppColors.primary, kNeonCyan],
      ),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F1220), Color(0xFF0A0D18)],
      ),
      neonPurple: kNeonPurple,
      neonCyan: kNeonCyan,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'Roboto',
      extensions: <ThemeExtension<dynamic>>[brand], // ← مهم
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        color: MaterialStateProperty.all(colorScheme.surfaceContainerHighest),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 24,
      ),
      inputDecorationTheme: _inputDecoration(colorScheme, isDark: true),
      elevatedButtonTheme: _elevatedButton(colorScheme),
      filledButtonTheme: _filledButton(colorScheme),
      outlinedButtonTheme: _outlinedButton(colorScheme),
      textButtonTheme: _textButton(colorScheme),
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith((s) =>
        s.contains(MaterialState.selected)
            ? AppColors.primary.withValues(alpha: 0.35)
            : colorScheme.surfaceContainerHighest),
        thumbColor: MaterialStateProperty.resolveWith((s) =>
        s.contains(MaterialState.selected)
            ? AppColors.primary
            : colorScheme.onSurface.withValues(alpha: 0.9)),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: colorScheme.outline,
        thumbColor: AppColors.primary,
      ),
      textTheme: _textThemeDark(base.textTheme),
      iconTheme:
      IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.9)),
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surface,
        iconColor: colorScheme.onSurface.withValues(alpha: 0.9),
        textColor: colorScheme.onSurface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ---- LIGHT THEME ----
  static ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      background: AppColors.lightBg,
      onBackground: AppColors.textPrimaryLight,
      surface: AppColors.lightSurface,
      onSurface: AppColors.textPrimaryLight,
      surfaceVariant: const Color(0xFFF0F0F5),
      outline: AppColors.lightOutline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: AppColors.textPrimaryDark,
      inversePrimary: AppColors.primaryDark,
    );

    // ThemeExtension برند
    final brand = const BrandTheme(
      primaryGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryDark, AppColors.primary, kNeonCyan],
      ),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF6F7FB), Color(0xFFF0F2F7)],
      ),
      neonPurple: kNeonPurple,
      neonCyan: kNeonCyan,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'Roboto',
      extensions: <ThemeExtension<dynamic>>[brand], // ← مهم
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        modalBackgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        color: MaterialStateProperty.all(colorScheme.surfaceContainerHighest),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 24,
      ),
      inputDecorationTheme: _inputDecoration(colorScheme, isDark: false),
      elevatedButtonTheme: _elevatedButton(colorScheme),
      filledButtonTheme: _filledButton(colorScheme),
      outlinedButtonTheme: _outlinedButton(colorScheme),
      textButtonTheme: _textButton(colorScheme),
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith((s) =>
        s.contains(MaterialState.selected)
            ? AppColors.primary.withValues(alpha: 0.25)
            : colorScheme.surfaceContainerHighest),
        thumbColor: MaterialStateProperty.resolveWith((s) =>
        s.contains(MaterialState.selected)
            ? AppColors.primary
            : colorScheme.onSurface.withValues(alpha: 0.95)),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: colorScheme.outline,
        thumbColor: AppColors.primary,
      ),
      textTheme: _textThemeLight(base.textTheme),
      iconTheme:
      IconThemeData(color: colorScheme.onSurface.withValues(alpha: 0.9)),
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surface,
        iconColor: colorScheme.onSurface.withValues(alpha: 0.9),
        textColor: colorScheme.onSurface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ---- Shared helpers ----
  static InputDecorationTheme _inputDecoration(ColorScheme cs,
      {required bool isDark}) {
    final fill = cs.surface;
    final hint =
    isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: 1),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: TextStyle(color: hint),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(cs.outline),
      focusedBorder: border(cs.primary),
      errorBorder: border(cs.error),
      focusedErrorBorder: border(cs.error),
      prefixIconColor: hint,
      suffixIconColor: hint,
      labelStyle: TextStyle(color: hint),
    );
  }

  static ElevatedButtonThemeData _elevatedButton(ColorScheme cs) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: const MaterialStatePropertyAll(0),
        backgroundColor: MaterialStatePropertyAll(cs.primary),
        foregroundColor: const MaterialStatePropertyAll(Colors.white),
        padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static FilledButtonThemeData _filledButton(ColorScheme cs) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        elevation: const MaterialStatePropertyAll(0),
        backgroundColor: MaterialStatePropertyAll(cs.secondary),
        foregroundColor: const MaterialStatePropertyAll(Colors.white),
        padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButton(ColorScheme cs) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStatePropertyAll(cs.primary),
        side: MaterialStatePropertyAll(
            BorderSide(color: cs.primary, width: 1.2)),
        padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static TextButtonThemeData _textButton(ColorScheme cs) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStatePropertyAll(cs.primary),
        padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static TextTheme _textThemeDark(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
      displayMedium: base.displayMedium?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
      headlineLarge: base.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
      headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      titleMedium: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      bodyLarge:
      base.bodyLarge?.copyWith(color: AppColors.textPrimaryDark),
      bodyMedium: base.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark),
      labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w600, color: Colors.white),
    );
  }

  static TextTheme _textThemeLight(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
      displayMedium: base.displayMedium?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
      headlineLarge: base.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
      headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      titleMedium: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      bodyLarge:
      base.bodyLarge?.copyWith(color: AppColors.textPrimaryLight),
      bodyMedium: base.bodyMedium?.copyWith(
          color: AppColors.textSecondaryLight),
      labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w600, color: Colors.white),
    );
  }
}

/// گرادیانت‌های آماده (اگر لازم شد)
class AppGradients {
  static const LinearGradient deepPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A0DAD), Color(0xFF8A2BE2)],
  );

  static const LinearGradient primaryGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8A2BE2), // primary
      Color(0xFFA64DFF), // secondary
      Color(0xFF7C83FD), // tertiary
    ],
  );
}
