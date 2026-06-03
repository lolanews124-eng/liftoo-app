// Run `.\scripts\setup-firebase.ps1` after `firebase login` to replace with real keys.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy0000000000000000000000000000000',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'liftoo-6672b',
    authDomain: 'liftoo-6672b.firebaseapp.com',
    storageBucket: 'liftoo-6672b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy0000000000000000000000000000000',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'liftoo-6672b',
    storageBucket: 'liftoo-6672b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy0000000000000000000000000000000',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'liftoo-6672b',
    storageBucket: 'liftoo-6672b.firebasestorage.app',
    iosBundleId: 'com.liftoo.liftooMobile',
  );

  static const FirebaseOptions macos = ios;
}
