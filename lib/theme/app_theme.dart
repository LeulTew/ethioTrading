/// AppTheme: Custom theming configuration for the Trading App.
/// This file defines both light and dark themes used throughout the application.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors - Enhanced
  static const Color _lightPrimary = Color(0xFF2E3192); // Rich royal blue
  static const Color _lightSecondary = Color(0xFF00B0FF); // Electric blue
  static const Color _lightBackground = Color(0xFFF9FAFC); // Premium off-white
  static const Color _lightSurface = Colors.white;
  static const Color _lightError = Color(0xFFE53935); // Vibrant red

  // Gradient Colors - More sophisticated
  static const List<Color> primaryGradient = [
    Color(0xFF3A1C71), // Deep indigo
    Color(0xFF4736B3), // Rich royal blue
    Color(0xFF5E60CE), // Periwinkle
  ];

  static const List<Color> accentGradient = [
    Color(0xFF00B4DB), // Bright cyan
    Color(0xFF0083B0), // Azure
    Color(0xFF00608B), // Deep azure
  ];

  // Additional gradients for premium look
  static const List<Color> successGradient = [
    Color(0xFF11998E), // Teal
    Color(0xFF38EF7D), // Spring green
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFF8008), // Amber
    Color(0xFFFFC837), // Golden
  ];

  // Adding the missing errorGradient
  static const List<Color> errorGradient = [
    Color(0xFFED213A), // Crimson
    Color(0xFF93291E), // Dark red
  ];

  // Dark Theme Colors - More sophisticated
  static const Color _darkPrimary = Color(0xFF6A5ACD); // Slate blue
  static const Color _darkSecondary = Color(0xFF56CCF2); // Sky blue
  static const Color _darkBackground = Color(0xFF121212); // Deep black
  static const Color _darkSurface = Color(0xFF1D1F2B); // Rich dark blue-gray
  static const Color _darkError = Color(0xFFFF5252); // Bright red

  // Trading Colors - More vibrant
  static const Color bullish = Color(0xFF00E676); // Bright mint green
  static const Color bearish = Color(0xFFFF3D00); // Vibrant orange-red
  static const Color neutral = Color(0xFF9E9E9E); // Medium gray

  // Chart Colors - More distinctive
  static const List<Color> chartColors = [
    Color(0xFF5E60CE), // Periwinkle
    Color(0xFFFF7C43), // Coral
    Color(0xFF00B4D8), // Ocean blue
    Color(0xFFFF5252), // Bright red
    Color(0xFFAA6AE0), // Lavender
    Color(0xFF2EC4B6), // Turquoise
    Color(0xFFFFD166), // Mustard
  ];

  // Technical Indicator Colors - Enhanced
  static const Color macdLine = Color(0xFF5E60CE); // Periwinkle
  static const Color signalLine = Color(0xFFFF7C43); // Coral
  static const Color histogram = Color(0xFF00B4D8); // Ocean blue
  static const Color rsiLine = Color(0xFF2EC4B6); // Turquoise
  static const Color bollingerBands = Color(0xFFAA6AE0); // Lavender
  static const Color movingAverage = Color(0xFFFF5252); // Bright red

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightSecondary,
        surface: _lightSurface,
        error: _lightError,
      ),
      scaffoldBackgroundColor: _lightBackground,
      cardTheme: CardTheme(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _lightSurface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: _lightPrimary,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _lightPrimary,
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: _lightPrimary,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightPrimary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide.none,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 24,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkSecondary,
        surface: _darkSurface,
        error: _darkError,
      ),
      scaffoldBackgroundColor: _darkBackground,
      cardTheme: const CardTheme(
        elevation: 4,
        margin: EdgeInsets.zero,
        color: _darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _darkBackground,
        foregroundColor: _darkPrimary,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: _darkPrimary,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide.none,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 24,
        thickness: 1,
      ),
    );
  }

  // Chart Theme
  static ChartThemeData chartTheme(bool isDarkMode) {
    return ChartThemeData(
      backgroundColor: isDarkMode ? _darkBackground : _lightBackground,
      gridLineColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      axisLineColor: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
      crosshairColor: isDarkMode ? Colors.white70 : Colors.black87,
      labelStyle: TextStyle(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        fontSize: 12,
      ),
    );
  }
}

class ChartThemeData {
  final Color backgroundColor;
  final Color gridLineColor;
  final Color axisLineColor;
  final Color crosshairColor;
  final TextStyle labelStyle;

  const ChartThemeData({
    required this.backgroundColor,
    required this.gridLineColor,
    required this.axisLineColor,
    required this.crosshairColor,
    required this.labelStyle,
  });
}
