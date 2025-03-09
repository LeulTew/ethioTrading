import 'package:flutter/foundation.dart';

/// Cross-browser compatible web utilities
class WebUtils {
  /// Returns true for web platforms
  static bool shouldInitializeApp() {
    return kIsWeb;
  }

  /// Initialize web-specific functionality with cross-browser support
  static void initPlatformSpecific() {
    if (!kIsWeb) return;

    // URL strategy is now configured in main.dart directly
    // This avoids the need to import flutter_web_plugins here
    if (kDebugMode) {
      print('Web platform initialized');
    }
  }

  /// Initialize web-platform for Firebase
  static void initWebFirebase() {
    if (!kIsWeb) return;
    // Firebase initialization is handled in index.html
  }
}
