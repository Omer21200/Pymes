import 'package:flutter/material.dart';

/// Centralized design tokens and themed values used across the app.
class AppColors {
  AppColors._();

  static const primary = Color(0xFFD92344);
  static const primaryDark = Color(0xFFA81830);
  // Admin/company specific tokens
  static const brandRed = Color(0xFFE2183D);
  static const brandRedAlt = Color(0xFFD92344);
  static const dangerRed = Color(0xFFD32F2F);
  static const accentBlueAdmin = Color(0xFF3F51B5);
  static const surfaceSoft = Color(0xFFF5F5F7);
  static const softBackground = Color(0xFFF5F6FA);
  static const blackSoft = Color(0xFF2D2D2D);
  static const mutedGray = Color(0xFF757575);
  static const linkRed = Color(0xFF8B3A3A);
  static const background = Color(0xFFF7F7F8);
  static const surface = Colors.white;
  static const lightGray = Color(0xFFF5F5F5);
  static const divider = Color(0xFFEEEEEE);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA500);
  static const accentBlue = Color(0xFF4A90E2);
  static const darkText = Color(0xFF333333);
  static const subtleBg = Color(0xFFF8F9FB);
  static const notificationBg = Color(0xFFFDEFF0);
}

class AppSizes {
  AppSizes._();

  static const double avatar = 60.0;
  static const double navHeight = 72.0;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );

  static const TextStyle largeTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
  );

  static const TextStyle smallLabel = TextStyle(
    fontSize: 12,
    color: Colors.black54,
  );

  static const TextStyle statsValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: Colors.black87,
    height: 1,
  );
}

class AppDecorations {
  AppDecorations._();

  static BoxDecoration headerGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.primaryDark],
    ),
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    ),
  );

  static BoxDecoration card = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
    ],
  );

  /// Builds a gradient and box shadow for stat cards that match admin dashboard.
  static BoxDecoration statCardDecoration(Color color) => BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.8), color]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))],
      );

  static BoxDecoration avatarContainer = const BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(colors: [Colors.white, AppColors.lightGray]),
    // shadows can be added where needed
  );
}

final ThemeData lightmode = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  scaffoldBackgroundColor: AppColors.background,
  dividerColor: AppColors.divider,
  appBarTheme: const AppBarTheme(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
);

final ThemeData darkmode = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
);
