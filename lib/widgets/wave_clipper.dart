import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveClipper extends CustomClipper<Path> {
  final double waveHeight;
  final double waveWidth;
  final double controlPointFactor;
  final double progress; // 0.0 to 1.0, to animate across the nav bar
  final bool waveOnTop;

  WaveClipper({
    required this.waveHeight,
    required this.waveWidth,
    this.controlPointFactor = 0.5,
    required this.progress,
    this.waveOnTop = true, // Default to wave on top
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    // Calculate wave position based on progress
    final navItemWidth = width / 4; // Assuming 4 nav items
    final waveCenter = navItemWidth * (progress + 0.5);

    if (waveOnTop) {
      // WAVE ON TOP IMPLEMENTATION
      // Start from top left
      path.moveTo(0, 0);

      // Draw top line to the start of the wave
      final waveStart = math.max(0.0, waveCenter - waveWidth / 2);
      path.lineTo(waveStart, 0);

      // Draw the wave (concave shape going downward)
      final controlPoint1X = waveStart + waveWidth * controlPointFactor;
      final controlPoint2X = waveStart + waveWidth * (1 - controlPointFactor);
      final waveEnd = math.min(width, waveCenter + waveWidth / 2);

      // Draw the downward curve
      path.cubicTo(controlPoint1X, 0, controlPoint1X, waveHeight, waveCenter,
          waveHeight);

      path.cubicTo(controlPoint2X, waveHeight, controlPoint2X, 0, waveEnd, 0);

      // Complete the rectangle
      path.lineTo(width, 0);
      path.lineTo(width, height);
      path.lineTo(0, height);
      path.close();
    } else {
      // WAVE ON BOTTOM IMPLEMENTATION (original)
      // Start from the bottom left
      path.moveTo(0, height);

      // Draw bottom line to the start of the wave
      final waveStart = math.max(0.0, waveCenter - waveWidth / 2);
      path.lineTo(waveStart, height);

      // Draw the wave
      final controlPoint1X = waveStart + waveWidth * controlPointFactor;
      final controlPoint2X = waveStart + waveWidth * (1 - controlPointFactor);
      final waveEnd = math.min(width, waveCenter + waveWidth / 2);

      path.cubicTo(controlPoint1X, height, controlPoint1X, height - waveHeight,
          waveCenter, height - waveHeight);

      path.cubicTo(controlPoint2X, height - waveHeight, controlPoint2X, height,
          waveEnd, height);

      // Complete the rectangle
      path.lineTo(width, height);
      path.lineTo(width, 0);
      path.lineTo(0, 0);
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) {
    return oldClipper.waveHeight != waveHeight ||
        oldClipper.waveWidth != waveWidth ||
        oldClipper.controlPointFactor != controlPointFactor ||
        oldClipper.progress != progress ||
        oldClipper.waveOnTop != waveOnTop;
  }
}

class SearchPillClipper extends CustomClipper<Path> {
  final double waveHeight;
  final double waveWidth;

  SearchPillClipper({
    this.waveHeight = 25.0,
    this.waveWidth = 120.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;

    // Start from the top-left corner with rounded edge
    path.moveTo(0, 20);
    path.quadraticBezierTo(0, 0, 20, 0);

    // Draw a line to where the wave starts
    path.lineTo(centerX - waveWidth / 2, 0);

    // Draw the wave (pill shape)
    path.quadraticBezierTo(
      centerX, // Control point X
      -waveHeight, // Control point Y (negative to make it curve upward)
      centerX + waveWidth / 2, // End point X
      0, // End point Y
    );

    // Complete the path by drawing to the remaining corners with rounded edges
    path.lineTo(size.width - 20, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 20);
    path.lineTo(size.width, size.height - 20);
    path.quadraticBezierTo(
        size.width, size.height, size.width - 20, size.height);
    path.lineTo(20, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 20);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
