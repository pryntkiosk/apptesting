import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not configured.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXO4w3GeV4FKBOpFyB7MHtcmyAcVSS37Q',
    appId: '1:1059639957857:android:08c3cab0c47721af0fcd20',
    messagingSenderId: '1059639957857',
    projectId: 'prynt-app',
    storageBucket: 'prynt-app.firebasestorage.app',
  );
}
