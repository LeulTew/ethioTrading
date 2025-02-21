// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

bool shouldInitializeApp() {
  if (!kIsWeb) return true;

  try {
    return html.window.location.toString() ==
        html.window.parent?.location.toString();
  } catch (e) {
    return true;
  }
}
