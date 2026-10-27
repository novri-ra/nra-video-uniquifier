import 'package:flutter/material.dart';

class AppColors {
  // Obsidian Surfaces
  static const Color background = Color(0xFF131315);
  static const Color surface = Color(0xFF131315);
  static const Color surfaceDim = Color(0xFF131315);
  static const Color surfaceBright = Color(0xFF39393B);
  static const Color surfaceContainerLowest = Color(0xFF0E0E10);
  static const Color surfaceContainerLow = Color(0xFF1C1B1D);
  static const Color surfaceContainer = Color(0xFF201F21);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2C);
  static const Color surfaceContainerHighest = Color(0xFF353437);

  // Mint Accents
  static const Color primary = Color(0xFFB7FFD9);
  static const Color onPrimary = Color(0xFF003824);
  static const Color primaryContainer = Color(0xFF00F0A8);
  static const Color onPrimaryContainer = Color(0xFF006847);
  static const Color secondary = Color(0xFF4DFFB2);
  static const Color onSecondary = Color(0xFF003822);
  static const Color secondaryContainer = Color(0xFF00E296);
  static const Color surfaceTint = Color(0xFF00E29E);

  // Text & Outlines
  static const Color onSurface = Color(0xFFE5E1E4);
  static const Color onSurfaceVariant = Color(0xFFB9CBBF);
  static const Color outline = Color(0xFF84958A);
  static const Color outlineVariant = Color(0xFF3B4A41);

  // Status & Error
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surfaceContainerLowest,
      canvasColor: AppColors.surfaceContainerLowest,
      primaryColor: AppColors.primaryContainer,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        margin: EdgeInsets.zero,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.surfaceContainerLowest;
          }
          return AppColors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryContainer;
          }
          return AppColors.surfaceContainer;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return AppColors.surfaceContainerHighest;
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        selectedItemColor: AppColors.primaryContainer,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
