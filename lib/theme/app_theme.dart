import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // =========================
  // 60% - MAIN BACKGROUND
  // =========================
  static const Color background = Color(0xFFFFFAF5);
  static const Color white = Color(0xFFFFFFFF);

  // =========================
  // 30% - LIGHT ORANGE
  // =========================
  static const Color primary = Color(0xFFFFD7A8);
  static const Color primaryLight = Color(0xFFFFEBD5);
  static const Color primarySoft = Color(0xFFFFF3E6);

  // =========================
  // 10% - ACCENT ORANGE
  // =========================
  static const Color accent = Color(0xFFE97816);
  static const Color accentDark = Color(0xFFC85B08);

  // =========================
  // TEXT
  // =========================
  static const Color black = Color(0xFF1F1F1F);

  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);

  // =========================
  // STATUS COLORS
  // =========================
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

class AppRadius {
  AppRadius._();

  static const double small = 8;
  static const double button = 12;
  static const double card = 16;
  static const double large = 24;
  static const double pill = 100;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,

      // 60%
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        primary: AppColors.accent,
        surface: AppColors.white,
      ),

      // =========================
      // APP BAR - 30%
      // =========================
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.black,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(
          color: AppColors.accentDark,
        ),
      ),

      // =========================
      // TEXT FIELDS
      // =========================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        hintStyle: const TextStyle(
          color: AppColors.grey500,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.3,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.3,
          ),
        ),

        // 10% accent when active
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(
            color: AppColors.accent,
            width: 2,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(
            color: AppColors.danger,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 2,
          ),
        ),
      ),

      // =========================
      // MAIN BUTTON - 10%
      // =========================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),

          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,

          elevation: 0,

          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),

      // =========================
      // ICONS
      // =========================
      iconTheme: const IconThemeData(
        color: AppColors.accentDark,
      ),

      // =========================
      // PROGRESS INDICATOR
      // =========================
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),

      // =========================
      // SNACKBAR
      // =========================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.black,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}