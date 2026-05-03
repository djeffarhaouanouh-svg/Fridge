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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyByCZcYDzY5LKPoK5g1N6oAjA2wXHkzLeg',
    appId: '1:21517907905:web:821166a83395349a2f2140',
    messagingSenderId: '21517907905',
    projectId: 'fridge-5f86b',
    authDomain: 'fridge-5f86b.firebaseapp.com',
    storageBucket: 'fridge-5f86b.firebasestorage.app',
    measurementId: 'G-2SWPTWT40Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCsUVx6Iw_o92PlNZSh1gMGETeKSw2gHT8',
    appId: '1:21517907905:android:bf67b451b591b6712f2140',
    messagingSenderId: '21517907905',
    projectId: 'fridge-5f86b',
    storageBucket: 'fridge-5f86b.firebasestorage.app',
  );

  // TODO: remplacer appId et bundleId par les valeurs iOS depuis Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyByCZcYDzY5LKPoK5g1N6oAjA2wXHkzLeg',
    appId: '1:21517907905:ios:REMPLACER_PAR_TON_APP_ID',
    messagingSenderId: '21517907905',
    projectId: 'fridge-5f86b',
    storageBucket: 'fridge-5f86b.firebasestorage.app',
    iosBundleId: 'com.myapp.fridgeIa',
  );
}
