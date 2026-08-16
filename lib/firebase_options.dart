import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.android:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_NqPpiRqyqQoumUcQtpTlicyXXSs3ru4',
    authDomain: 'bn24-personalizados.firebaseapp.com',
    projectId: 'bn24-personalizados',
    storageBucket: 'bn24-personalizados.firebasestorage.app',
    messagingSenderId: '467458602774',
    appId: '1:467458602774:web:6fee3090cb5a6f77fc8237',
    measurementId: 'G-8LL2XRDKLR',
  );
}
