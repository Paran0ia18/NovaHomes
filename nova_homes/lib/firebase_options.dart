import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Replace this file by running:
/// `flutterfire configure`
/// The generated file will contain your real Firebase project keys.
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
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: 'REPLACE_WITH_FLUTTERFIRE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE',
    authDomain: 'REPLACE_WITH_FLUTTERFIRE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: 'REPLACE_WITH_FLUTTERFIRE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: 'REPLACE_WITH_FLUTTERFIRE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE',
    iosBundleId: 'com.example.novaHomes',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: 'REPLACE_WITH_FLUTTERFIRE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE',
    iosBundleId: 'com.example.novaHomes',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: 'REPLACE_WITH_FLUTTERFIRE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE',
    authDomain: 'REPLACE_WITH_FLUTTERFIRE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE',
    appId: 'REPLACE_WITH_FLUTTERFIRE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE',
    authDomain: 'REPLACE_WITH_FLUTTERFIRE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE',
  );
}
