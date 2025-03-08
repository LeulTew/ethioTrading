// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/env.dart';
import 'package:logging/logging.dart';

final _logger = Logger('WebUtils');

bool shouldInitializeApp() {
  if (!kIsWeb) return true;

  try {
    return html.window.location.toString() ==
        html.window.parent?.location.toString();
  } catch (e) {
    return true;
  }
}

// Initialize web-specific functionality
void initPlatformSpecific() {
  _injectFirebaseApiKey();
}

// Function to inject Firebase API key into web page
void _injectFirebaseApiKey() {
  try {
    // Create a script that directly adds the API key to the window
    const String script = '''
      // Add the Firebase API key to the window object
      window.FIREBASE_API_KEY = "${Env.firebaseApiKey}";
    ''';

    // Inject the script into the page
    final scriptElement = html.ScriptElement()
      ..type = 'text/javascript'
      ..innerHtml = script;

    // Add it to the beginning of the head to ensure it's available early
    html.document.head!
        .insertBefore(scriptElement, html.document.head!.firstChild);
  } catch (e) {
    _logger.warning('Error injecting Firebase API key: $e');
  }
}
