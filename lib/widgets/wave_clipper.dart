import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  final double waveHeight;
  final double waveWidth;
  
  WaveClipper({
    this.waveHeight = 30.0,
    this.waveWidth = 120.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    
    // Start from the top-left corner
    path.moveTo(0, 0);
    
    // Draw a line to where the wave starts
    path.lineTo(centerX - waveWidth, 0);
    
    // Draw the wave with a more elegant curve that extends into the page
    path.quadraticBezierTo(
      centerX - waveWidth / 2, // Control point X
      -waveHeight, // Control point Y (negative to make it curve upward)
      centerX, // End point X
      0, // End point Y
    );
    
    path.quadraticBezierTo(
      centerX + waveWidth / 2, // Control point X
      waveHeight, // Control point Y (positive to make it curve downward)
      centerX + waveWidth, // End point X
      0, // End point Y
    );
    
    // Complete the path by drawing to the remaining corners
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
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
    path.quadraticBezierTo(size.width, size.height, size.width - 20, size.height);
    path.lineTo(20, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 20);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}