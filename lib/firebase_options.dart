// IMPORTANT: Replace this file by running:  flutterfire configure
// Until you do, Firebase features are disabled and the app runs in offline mode.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_API_KEY',
    appId: 'REPLACE_WITH_YOUR_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    authDomain: 'REPLACE_WITH_YOUR_AUTH_DOMAIN',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGA0e1UyXgIC9Z2SK2rWN1xlbU1Q3-L8Y',
    appId: '1:172342626558:android:1a2d339050b14f65673daf',
    messagingSenderId: '172342626558',
    projectId: 'salah-socials',
    storageBucket: 'salah-socials.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCgFAh6dB5STJcZ__oe_8s-pyJ6TLvKthQ',
    appId: '1:172342626558:ios:75fdf48045680dbf673daf',
    messagingSenderId: '172342626558',
    projectId: 'salah-socials',
    storageBucket: 'salah-socials.firebasestorage.app',
    iosClientId: '172342626558-0ke4iafponpj29ugpbvs4jdqa425s8mq.apps.googleusercontent.com',
    iosBundleId: 'com.example.salahSocials',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_API_KEY',
    appId: 'REPLACE_WITH_YOUR_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_YOUR_STORAGE_BUCKET',
    iosClientId: 'REPLACE_WITH_YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.salahSocials',
  );
}