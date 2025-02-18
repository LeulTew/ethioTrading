/// AppTheme: Custom theming configuration for the Trading App.
/// This file defines both light and dark themes used throughout the application.
library;

import 'package:flutter/material.dart';

class AppTheme {
  /// Returns a fully configured custom light theme.
  static ThemeData lightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: _lightTextTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Background color
          foregroundColor: Colors.white, // Text color
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        labelStyle: TextStyle(color: Colors.blue),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.blue.shade100,
        disabledColor: Colors.grey.shade300,
        selectedColor: Colors.blue.shade300,
        secondarySelectedColor: Colors.blue.shade300,
        padding: const EdgeInsets.all(8),
        labelStyle: const TextStyle(color: Colors.black),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.blue,
        inactiveTrackColor: Colors.blue.shade100,
        thumbColor: Colors.blueAccent,
        overlayColor: Colors.blue.withAlpha(51),
      ),
    );
  }

  /// Returns a fully configured custom dark theme.
  static ThemeData darkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      brightness: Brightness.dark,
      primaryColor: Colors.blueGrey,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blueGrey.shade900,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: _darkTextTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey, // Background color
          foregroundColor: Colors.white, // Text color
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey),
        ),
        labelStyle: TextStyle(color: Colors.blueGrey),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.blueGrey.shade800,
        disabledColor: Colors.grey.shade700,
        selectedColor: Colors.blueGrey.shade600,
        secondarySelectedColor: Colors.blueGrey.shade600,
        padding: const EdgeInsets.all(8),
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.dark,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.blueGrey,
        inactiveTrackColor: Colors.blueGrey.shade700,
        thumbColor: Colors.blueAccent,
        overlayColor: Colors.blueGrey.withAlpha(51),
      ),
    );
  }

  /// Custom text theme for light mode.
  static TextTheme _lightTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
      displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
      displaySmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
      headlineLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
      headlineMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
      headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
      titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
      titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
      bodyLarge: const TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: const TextStyle(fontSize: 14, color: Colors.black87),
      bodySmall: const TextStyle(fontSize: 12, color: Colors.black54),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black),
      labelSmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black),
    );
  }

  /// Custom text theme for dark mode.
  static TextTheme _darkTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white70),
      displaySmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white70),
      headlineLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white70),
      headlineMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white70),
      headlineSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70),
      titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
      titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
      bodyLarge: const TextStyle(fontSize: 16, color: Colors.white70),
      bodyMedium: const TextStyle(fontSize: 14, color: Colors.white70),
      bodySmall: const TextStyle(fontSize: 12, color: Colors.white60),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      labelSmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
    );
  }
}
