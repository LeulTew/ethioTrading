// Initialize platform-specific functionality for non-web platforms

/// Initialize platform-specific functionality for non-web platforms
void initPlatformSpecific() {
  print('Initializing non-web platform specifics');
  // No special initialization needed for non-web platforms
}

/// Called from main.dart, delegating to initPlatformSpecific
void initPlatformIO() {
  // This is a wrapper for the original function to maintain compatibility
  initPlatformSpecific();
}

/// For consistency with web_utils.dart
bool shouldInitializeApp() {
  return true;
}
