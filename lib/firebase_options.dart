// Generated from android/app/google-services.json for project cdnnetchat-7db90.
//
// If you reconfigure Firebase, regenerate this file using:
//     flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyC4QhbOlEb5Ckww1qbrV0KSAsQfDn5iltw',
    appId: '1:959335831358:web:36bbf127a30d00e51c3e6f',
    messagingSenderId: '959335831358',
    projectId: 'cdnnetchat-7db90',
    storageBucket: 'cdnnetchat-7db90.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4QhbOlEb5Ckww1qbrV0KSAsQfDn5iltw',
    appId: '1:959335831358:android:36bbf127a30d00e51c3e6f',
    messagingSenderId: '959335831358',
    projectId: 'cdnnetchat-7db90',
    storageBucket: 'cdnnetchat-7db90.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4QhbOlEb5Ckww1qbrV0KSAsQfDn5iltw',
    appId: '1:959335831358:ios:36bbf127a30d00e51c3e6f',
    messagingSenderId: '959335831358',
    projectId: 'cdnnetchat-7db90',
    storageBucket: 'cdnnetchat-7db90.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC4QhbOlEb5Ckww1qbrV0KSAsQfDn5iltw',
    appId: '1:959335831358:macos:36bbf127a30d00e51c3e6f',
    messagingSenderId: '959335831358',
    projectId: 'cdnnetchat-7db90',
    storageBucket: 'cdnnetchat-7db90.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC4QhbOlEb5Ckww1qbrV0KSAsQfDn5iltw',
    appId: '1:959335831358:windows:36bbf127a30d00e51c3e6f',
    messagingSenderId: '959335831358',
    projectId: 'cdnnetchat-7db90',
    storageBucket: 'cdnnetchat-7db90.firebasestorage.app',
  );
}
