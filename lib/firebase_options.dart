import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for the current platform
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDk6ydogSjQ6hohlxF_jGmxubSDosQPH68',
    appId: '1:1037800105398:web:477e073d91c9a8bf794d17',
    messagingSenderId: '1037800105398',
    projectId: 'ethio-tradding-app-9af0d',
    authDomain: 'ethio-tradding-app-9af0d.firebaseapp.com',
    storageBucket: 'ethio-tradding-app-9af0d.firebasestorage.app',
    measurementId: 'G-GLFX8LEDJH',
    databaseURL: 'https://ethio-tradding-app-9af0d.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDk6ydogSjQ6hohlxF_jGmxubSDosQPH68',
    appId: '1:1037800105398:android:477e073d91c9a8bf794d17',
    messagingSenderId: '1037800105398',
    projectId: 'ethio-tradding-app-9af0d',
    storageBucket: 'ethio-tradding-app-9af0d.firebasestorage.app',
    databaseURL: 'https://ethio-tradding-app-9af0d.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDk6ydogSjQ6hohlxF_jGmxubSDosQPH68',
    appId: '1:1037800105398:ios:477e073d91c9a8bf794d17',
    messagingSenderId: '1037800105398',
    projectId: 'ethio-tradding-app-9af0d',
    storageBucket: 'ethio-tradding-app-9af0d.firebasestorage.app',
    databaseURL: 'https://ethio-tradding-app-9af0d.firebaseio.com',
    iosClientId: '1037800105398-ios-client-id',
    iosBundleId: 'com.example.ethioTradingApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDk6ydogSjQ6hohlxF_jGmxubSDosQPH68',
    appId: '1:1037800105398:macos:477e073d91c9a8bf794d17',
    messagingSenderId: '1037800105398',
    projectId: 'ethio-tradding-app-9af0d',
    storageBucket: 'ethio-tradding-app-9af0d.firebasestorage.app',
    databaseURL: 'https://ethio-tradding-app-9af0d.firebaseio.com',
  );
}
