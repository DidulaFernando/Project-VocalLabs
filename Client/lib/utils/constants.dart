// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF7C2474);
  static const Color lightBlue = Color(
    0xFF9E4696,
  ); // Lighter variant of the purple
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color lightText = Color(
    0xFFE0E0E0,
  ); // Changed from 0xFF757575 to a lighter shade
  static const Color background = Color(
    0xFF342E3D,
  ); // Changed from Colors.white
  static const Color cardBackground = Color.fromARGB(
    255,
    117,
    79,
    129,
  ); // Changed to darker purple
  static const Color accent = Color(0xFFE284FF);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    color: AppColors.darkText,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    color: AppColors.lightText,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppPadding {
  static const EdgeInsets screenPadding = EdgeInsets.all(20.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
}
