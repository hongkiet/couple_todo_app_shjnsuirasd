import 'package:flutter/material.dart';

/// Theme configuration cho ứng dụng CoupleS
/// Sử dụng font Inter để có giao diện giống Instagram
class AppTheme {
  // Font family chính
  static const String fontFamily = 'Inter';

  // Màu sắc chính (giữ nguyên màu pink hiện tại)
  static const Color primaryColor = Colors.pink;

  /// Theme sáng (Light Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryColor,
      fontFamily: fontFamily,

      // Cấu hình TextTheme với font Inter
      textTheme: const TextTheme(
        // Display styles - cho tiêu đề lớn
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700, // Bold
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w600, // SemiBold
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600, // SemiBold
        ),

        // Headline styles - cho tiêu đề
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600, // SemiBold
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w500, // Medium
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w500, // Medium
        ),

        // Title styles - cho tiêu đề nhỏ
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500, // Medium
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500, // Medium
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500, // Medium
        ),

        // Body styles - cho nội dung chính
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400, // Regular
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400, // Regular
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400, // Regular
        ),

        // Label styles - cho nhãn và button
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500, // Medium
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500, // Medium
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500, // Medium
        ),
      ),

      // Cấu hình AppBar theme
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600, // SemiBold
          color: Colors.black87,
        ),
      ),

      // Cấu hình ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500, // Medium
          ),
        ),
      ),

      // Cấu hình FilledButton theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500, // Medium
          ),
        ),
      ),

      // Cấu hình TextButton theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500, // Medium
          ),
        ),
      ),

      // Cấu hình InputDecoration theme
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400, // Regular
        ),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400, // Regular
        ),
      ),
    );
  }

  /// Theme tối (Dark Theme) - có thể sử dụng sau này
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryColor,
      brightness: Brightness.dark,
      fontFamily: fontFamily,

      // Sử dụng cùng TextTheme nhưng với màu sắc phù hợp với dark mode
      textTheme: lightTheme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600, // SemiBold
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Extension để dễ dàng sử dụng font weights
extension FontWeightExtension on FontWeight {
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}
