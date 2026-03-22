// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors - Calm but animative palette
  static const Color lightPrimary = Color(0xFF5E8BFF); // Soft blue
  static const Color lightSecondary = Color(0xFF9B6BFF); // Soft purple
  static const Color lightTertiary = Color(0xFFFF9F6E); // Warm coral
  static const Color lightBackground = Color(0xFFF8FAFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A2C3E);
  static const Color lightTextSecondary = Color(0xFF5C6F87);
  static const Color lightDivider = Color(0xFFE8ECF2);
  static const Color lightCardShadow = Color(0xFF1A2C3E);

  // Dark Theme Colors - Calm and soothing
  static const Color darkPrimary = Color(0xFF7B9CFF);
  static const Color darkSecondary = Color(0xFFB28CFF);
  static const Color darkTertiary = Color(0xFFFFB47B);
  static const Color darkBackground = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF151C2C);
  static const Color darkTextPrimary = Color(0xFFF0F3FA);
  static const Color darkTextSecondary = Color(0xFF9AA9C1);
  static const Color darkDivider = Color(0xFF2A3448);
  static const Color darkCardShadow = Color(0xFF000000);

  // Gradient Stops for Animations
  static const List<Color> gradientStart = [lightPrimary, lightSecondary];
  static const List<Color> gradientEnd = [lightSecondary, lightTertiary];

  static const List<Color> darkGradientStart = [darkPrimary, darkSecondary];
  static const List<Color> darkGradientEnd = [darkSecondary, darkTertiary];

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);

  // XP & Gamification Colors
  static const Color xpGold = Color(0xFFFFB74D);
  static const Color xpSilver = Color(0xFFB0BEC5);
  static const Color xpBronze = Color(0xFFFF8A65);
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        tertiary: AppColors.lightTertiary,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightDivider,

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.lightTextPrimary,
          letterSpacing: -0.4,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.lightTextSecondary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.lightTextSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.lightPrimary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        indicatorColor: AppColors.lightPrimary.withOpacity(0.12),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        tertiary: AppColors.darkTertiary,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkDivider,

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.darkTextPrimary,
          letterSpacing: -0.4,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.darkTextSecondary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.darkTextSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkPrimary,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
      ),

      // cardTheme: CardTheme(
      //   elevation: 0,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(24),
      //   ),
      //   clipBehavior: Clip.antiAlias,
      // ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        indicatorColor: AppColors.darkPrimary.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
