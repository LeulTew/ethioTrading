/// Default implementation for non-web platforms
class WebUtilsImpl {
  /// Always returns true on non-web platforms
  static bool shouldInitializeApp() {
    return true;
  }

  /// No-op on non-web platforms
  static void injectFirebaseApiKey(String apiKey) {
    // No-op on non-web platforms
  }
}
