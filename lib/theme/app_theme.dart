/// AppTheme: Custom theming configuration for the Trading App.
/// This file defines both light and dark themes used throughout the application.
library;

import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color _lightPrimary = Color(0xFF1B5E20);
  static const Color _lightSecondary = Color(0xFF2E7D32);
  static const Color _lightBackground = Color(0xFFF5F5F5);
  static const Color _lightSurface = Colors.white;
  static const Color _lightError = Color(0xFFB00020);

  // Dark Theme Colors
  static const Color _darkPrimary = Color(0xFF81C784);
  static const Color _darkSecondary = Color(0xFF82B086);
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkError = Color(0xFFCF6679);

  // Trading Colors
  static const Color bullish = Color(0xFF00C853);
  static const Color bearish = Color(0xFFD50000);
  static const Color neutral = Color(0xFF757575);

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFFFA726), // Orange
    Color(0xFF66BB6A), // Green
    Color(0xFFEF5350), // Red
    Color(0xFF8E24AA), // Purple
    Color(0xFF26A69A), // Teal
  ];

  // Technical Indicator Colors
  static const Color macdLine = Color(0xFF2196F3);
  static const Color signalLine = Color(0xFFFFA726);
  static const Color histogram = Color(0xFF66BB6A);
  static const Color rsiLine = Color(0xFF26A69A);
  static const Color bollingerBands = Color(0xFF8E24AA);
  static const Color movingAverage = Color(0xFFEF5350);

  static ThemeData lightTheme() {
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
      cardTheme: const CardTheme(
        elevation: 2,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _lightBackground,
        foregroundColor: _lightPrimary,
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

  static ThemeData darkTheme() {
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
