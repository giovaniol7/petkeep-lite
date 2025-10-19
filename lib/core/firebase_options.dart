
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
    apiKey: 'AIzaSyAMAhDhpsbClk6iSjTxIgWs6EOvUF6AVaI',
    appId: '1:117457996829:web:e7ebe140bb609e4659caf4',
    messagingSenderId: '117457996829',
    projectId: 'petkeeper-lite',
    authDomain: 'petkeeper-lite.firebaseapp.com',
    storageBucket: 'petkeeper-lite.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCoS9zGXRbGQbRB3TuPKu-6Lx4qh3WU6kI',
    appId: '1:117457996829:android:1ba2927ad8dda6b559caf4',
    messagingSenderId: '117457996829',
    projectId: 'petkeeper-lite',
    storageBucket: 'petkeeper-lite.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtvnCCrFQXvJ-VY16_HJf938t_G2sCyic',
    appId: '1:117457996829:ios:436c996c3112194559caf4',
    messagingSenderId: '117457996829',
    projectId: 'petkeeper-lite',
    storageBucket: 'petkeeper-lite.firebasestorage.app',
    iosClientId: '117457996829-1gedtl3letm23m8snlj5p65roip1ocfk.apps.googleusercontent.com',
    iosBundleId: 'com.example.petkeeperLite',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDtvnCCrFQXvJ-VY16_HJf938t_G2sCyic',
    appId: '1:117457996829:ios:436c996c3112194559caf4',
    messagingSenderId: '117457996829',
    projectId: 'petkeeper-lite',
    storageBucket: 'petkeeper-lite.firebasestorage.app',
    iosClientId: '117457996829-1gedtl3letm23m8snlj5p65roip1ocfk.apps.googleusercontent.com',
    iosBundleId: 'com.example.petkeeperLite',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAMAhDhpsbClk6iSjTxIgWs6EOvUF6AVaI',
    appId: '1:117457996829:web:3664d924729333cc59caf4',
    messagingSenderId: '117457996829',
    projectId: 'petkeeper-lite',
    authDomain: 'petkeeper-lite.firebaseapp.com',
    storageBucket: 'petkeeper-lite.firebasestorage.app',
  );

}