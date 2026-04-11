import 'package:flutter/material.dart';

class AppColors {
	static const Color background = Color(0xFFFFFFFF);
	static const Color cardBackground = Color(0xFFF5F5F5);
	static const Color cardBorder = Color(0xFFEEEEEE);

	static const Color textPrimary = Color(0xFF111111);
	static const Color textSecondary = Color(0xFF666666);
	static const Color textTertiary = Color(0xFF999999);

	static const Color accent = Color(0xFF333333);
	static const Color divider = Color(0xFFE0E0E0);

	static const Color darkBackground = Color(0xFF111111);
	static const Color darkCardBackground = Color(0xFF1B1B1B);
	static const Color darkCardBorder = Color(0xFF2A2A2A);
	static const Color darkTextPrimary = Color(0xFFF5F5F5);
	static const Color darkTextSecondary = Color(0xFFCCCCCC);
	static const Color darkTextTertiary = Color(0xFF999999);
	static const Color darkAccent = Color(0xFFE0E0E0);
	static const Color darkDivider = Color(0xFF2F2F2F);
}

class AppTheme {
	static ThemeData lightTheme() {
		final colorScheme = ColorScheme.fromSeed(
			seedColor: AppColors.accent,
			brightness: Brightness.light,
			primary: AppColors.accent,
			surface: AppColors.background,
		);

		return ThemeData(
			useMaterial3: true,
			brightness: Brightness.light,
			colorScheme: colorScheme,
			scaffoldBackgroundColor: AppColors.background,
			dividerColor: AppColors.divider,
			appBarTheme: const AppBarTheme(
				backgroundColor: AppColors.background,
				foregroundColor: AppColors.textPrimary,
				elevation: 0,
				centerTitle: false,
			),
			cardTheme: const CardThemeData(
				color: AppColors.background,
				elevation: 1,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.all(Radius.circular(12)),
					side: BorderSide(color: AppColors.cardBorder),
				),
			),
			chipTheme: ChipThemeData(
				side: BorderSide.none,
				shape: const StadiumBorder(),
				selectedColor: AppColors.textPrimary,
				backgroundColor: AppColors.cardBackground,
				labelStyle: const TextStyle(
					color: AppColors.textSecondary,
					fontWeight: FontWeight.w500,
				),
			),
			textTheme: const TextTheme(
				headlineMedium: TextStyle(
					fontSize: 24,
					fontWeight: FontWeight.w700,
					color: AppColors.textPrimary,
				),
				bodyLarge: TextStyle(
					fontSize: 16,
					fontWeight: FontWeight.w600,
					color: AppColors.textPrimary,
				),
				bodyMedium: TextStyle(
					fontSize: 14,
					fontWeight: FontWeight.w400,
					color: AppColors.textSecondary,
				),
				bodySmall: TextStyle(
					fontSize: 12,
					fontWeight: FontWeight.w500,
					color: AppColors.textTertiary,
				),
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: AppColors.cardBackground,
				contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide.none,
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide.none,
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.accent),
				),
			),
		);
	}

	static ThemeData darkTheme() {
		final colorScheme = ColorScheme.fromSeed(
			seedColor: AppColors.darkAccent,
			brightness: Brightness.dark,
			primary: AppColors.darkAccent,
			surface: AppColors.darkBackground,
		);

		return ThemeData(
			useMaterial3: true,
			brightness: Brightness.dark,
			colorScheme: colorScheme,
			scaffoldBackgroundColor: AppColors.darkBackground,
			dividerColor: AppColors.darkDivider,
			appBarTheme: const AppBarTheme(
				backgroundColor: AppColors.darkBackground,
				foregroundColor: AppColors.darkTextPrimary,
				elevation: 0,
				centerTitle: false,
			),
			cardTheme: const CardThemeData(
				color: AppColors.darkCardBackground,
				elevation: 1,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.all(Radius.circular(12)),
					side: BorderSide(color: AppColors.darkCardBorder),
				),
			),
			chipTheme: ChipThemeData(
				side: BorderSide.none,
				shape: const StadiumBorder(),
				selectedColor: AppColors.darkTextPrimary,
				backgroundColor: AppColors.darkCardBackground,
				labelStyle: const TextStyle(
					color: AppColors.darkTextSecondary,
					fontWeight: FontWeight.w500,
				),
			),
			textTheme: const TextTheme(
				headlineMedium: TextStyle(
					fontSize: 24,
					fontWeight: FontWeight.w700,
					color: AppColors.darkTextPrimary,
				),
				bodyLarge: TextStyle(
					fontSize: 16,
					fontWeight: FontWeight.w600,
					color: AppColors.darkTextPrimary,
				),
				bodyMedium: TextStyle(
					fontSize: 14,
					fontWeight: FontWeight.w400,
					color: AppColors.darkTextSecondary,
				),
				bodySmall: TextStyle(
					fontSize: 12,
					fontWeight: FontWeight.w500,
					color: AppColors.darkTextTertiary,
				),
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: AppColors.darkCardBackground,
				contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
				border: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide.none,
				),
				enabledBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: BorderSide.none,
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: BorderRadius.circular(12),
					borderSide: const BorderSide(color: AppColors.darkAccent),
				),
			),
		);
	}
}
