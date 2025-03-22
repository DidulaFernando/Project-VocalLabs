import 'package:flutter/material.dart';

class AppColors {
  static const primaryDark = Color(0xFF190115); // Dark purple background
  static const primary = Color(0xFF7C2474); // light purple as primary
  static const white = Colors.white;

  // High contrast text colors
  static const brightText = Color(
    0xFFFFFAFF,
  ); // Nearly white with slight warmth
  static const highlightText = Color(0xFFFFE6FF); // Bright pink-white
  static const accentText = Color(0xFF9E4696); // Lighter variant
  static const secondaryText = Color(0xFFAF6BA8); // Even lighter variant

  // Card backgrounds
  static const cardBackground = Color(
    0xFF2D1A2A,
  ); // Slightly lighter than primaryDark

  // Navigation bar colors
  static const navBarBackground = Color(
    0xFF2D1B29,
  ); // Darker purple for nav bar
  static const navBarIconInactive = Color(
    0xFF2D1A2A,
  ); // Light gray-white for unselected icons
  static const navBarIconActive = Color(
    0xFF7C2474,
  ); // New light purple for active icons
}

class AppTextStyles {
  // Primary heading for dark backgrounds
  static const heading1 = TextStyle(
    color: AppColors.brightText,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    shadows: [
      Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4),
    ],
  );

  // Secondary heading for dark backgrounds
  static const heading2 = TextStyle(
    color: AppColors.accentText,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    shadows: [
      Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 3),
    ],
  );

  // Body text for dark backgrounds
  static const body2 = TextStyle(
    color: AppColors.brightText,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0.2,
    shadows: [
      Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2),
    ],
  );

  // Styles for card contexts
  static const cardHeading = TextStyle(
    color: AppColors.highlightText,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    shadows: [
      Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 3),
    ],
  );

  static const cardBody = TextStyle(
    color: AppColors.brightText,
    fontSize: 15,
    height: 1.4,
    letterSpacing: 0.2,
    shadows: [
      Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
    ],
  );

  // Button and interactive element text
  static const buttonText = TextStyle(
    color: AppColors.brightText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.primaryDark,
      cardColor: AppColors.cardBackground,
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.brightText,
        titleTextStyle: TextStyle(
          color: AppColors.brightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.brightText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.brightText,
          minimumSize: const Size(double.infinity, 63),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(38),
          ),
          elevation: 8,
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentText,
          textStyle: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.brightText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(color: AppColors.brightText),
        displaySmall: TextStyle(color: AppColors.brightText),
        headlineLarge: TextStyle(color: AppColors.brightText),
        headlineMedium: TextStyle(color: AppColors.accentText),
        headlineSmall: TextStyle(color: AppColors.accentText),
        titleLarge: TextStyle(color: AppColors.highlightText),
        titleMedium: TextStyle(color: AppColors.accentText),
        titleSmall: TextStyle(color: AppColors.accentText),
        bodyLarge: TextStyle(color: AppColors.brightText),
        bodyMedium: TextStyle(color: AppColors.brightText),
        bodySmall: TextStyle(color: AppColors.brightText),
        labelLarge: TextStyle(color: AppColors.accentText),
        labelMedium: TextStyle(color: AppColors.brightText),
        labelSmall: TextStyle(color: AppColors.brightText),
      ).apply(
        bodyColor: AppColors.brightText,
        displayColor: AppColors.brightText,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        background: AppColors.primaryDark,
        onBackground: AppColors.brightText,
        surface: AppColors.cardBackground,
        onSurface: AppColors.brightText,
        onPrimary: AppColors.brightText,
        onSecondary: AppColors.accentText,
        onError: AppColors.brightText,
        tertiary: AppColors.secondaryText,
        onTertiary: AppColors.brightText,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.navBarIconActive,
        unselectedItemColor: AppColors.navBarIconInactive,
        selectedIconTheme: IconThemeData(
          size: 24,
          color: AppColors.navBarIconActive,
        ),
        unselectedIconTheme: IconThemeData(
          size: 22,
          color: AppColors.navBarIconInactive,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Color.fromRGBO(72, 23, 68, 1),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A4255)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: Colors.white, // Empty part color
        color: AppColors.primary, // Progress color
        refreshBackgroundColor:
            Colors.white, // Background color for circular progress
      ),
    );
  }
}
