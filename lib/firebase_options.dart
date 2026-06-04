// Generated from Firebase project liftoo-6672b (flutterfire configure / google-services.json).
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
    apiKey: 'AIzaSyCtBUfvyH8b4ZBlJcTesr3M-PNHmWYQsPY',
    appId: '1:871816301139:web:0000000000000000000000',
    messagingSenderId: '871816301139',
    projectId: 'liftoo-6672b',
    authDomain: 'liftoo-6672b.firebaseapp.com',
    storageBucket: 'liftoo-6672b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtBUfvyH8b4ZBlJcTesr3M-PNHmWYQsPY',
    appId: '1:871816301139:android:a9349c531299081b5394a6',
    messagingSenderId: '871816301139',
    projectId: 'liftoo-6672b',
    storageBucket: 'liftoo-6672b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCEPzSnnDiA1nsQkBjIDbq2OW1C3zXjmnA',
    appId: '1:871816301139:ios:a8b24e61a71d6f5e5394a6',
    messagingSenderId: '871816301139',
    projectId: 'liftoo-6672b',
    storageBucket: 'liftoo-6672b.firebasestorage.app',
    iosBundleId: 'com.liftoo.liftooMobile',
  );

  static const FirebaseOptions macos = ios;
}
