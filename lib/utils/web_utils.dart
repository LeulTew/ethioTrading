import 'package:flutter/foundation.dart' show kIsWeb;

/// Cross-browser compatible web utilities
class WebUtils {
  /// Returns true for web platforms
  static bool shouldInitializeApp() {
    return kIsWeb;
  }

  /// Initialize web-specific functionality with cross-browser support
  static void initPlatformSpecific() {
    if (!kIsWeb) return;
    // All web initialization is now handled in index.html
  }

  /// Initialize web-platform for Firebase
  static void initWebFirebase() {
    if (!kIsWeb) return;
    // Firebase initialization is handled in index.html
  }
}
