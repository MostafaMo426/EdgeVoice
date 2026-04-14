import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCHNaSCX9n80IJIj5P_ur1-Pv0JvSJxrZU',
    appId: '1:284637742388:web:7f6f1c4a0f4a4c4a4c4a4c', // Placeholder, but allows init
    messagingSenderId: '284637742388',
    projectId: 'voice-assistant-2e03d',
    authDomain: 'voice-assistant-2e03d.firebaseapp.com',
    storageBucket: 'voice-assistant-2e03d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCHNaSCX9n80IJIj5P_ur1-Pv0JvSJxrZU',
    appId: '1:284637742388:android:ad295868df00cb10b89161',
    messagingSenderId: '284637742388',
    projectId: 'voice-assistant-2e03d',
    storageBucket: 'voice-assistant-2e03d.firebasestorage.app',
  );
}
