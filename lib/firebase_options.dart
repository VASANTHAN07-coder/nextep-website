import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyABuehuvSKFwYztry0jL0oUXZuHbcF98fc',
    appId: '1:507210518116:web:41addbed0d4b58dd7cd971', // Deduced fallback
    messagingSenderId: '507210518116',
    projectId: 'college-backend-prod',
    authDomain: 'college-backend-prod.firebaseapp.com',
    storageBucket: 'college-backend-prod.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyABuehuvSKFwYztry0jL0oUXZuHbcF98fc',
    appId: '1:507210518116:android:41addbed0d4b58dd7cd971',
    messagingSenderId: '507210518116',
    projectId: 'college-backend-prod',
    storageBucket: 'college-backend-prod.firebasestorage.app',
  );
}
