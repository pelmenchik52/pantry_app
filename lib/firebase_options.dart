// ЗАГЛУШКА. Цей файл потрібно ПЕРЕЗАПИСАТИ командою:
//   flutterfire configure
// Після неї тут з'являться реальні ключі вашого Firebase-проєкту.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Проєкт налаштований лише для Web. Запустіть: flutterfire configure',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAFjs3KrECnrIFQwV12vHZgvJBOUnEkmfA',
    appId: '1:243379524954:web:3305d24d9c6e056f838f63',
    messagingSenderId: '243379524954',
    projectId: 'pantry-app-c4245',
    authDomain: 'pantry-app-c4245.firebaseapp.com',
    storageBucket: 'pantry-app-c4245.firebasestorage.app',
    measurementId: 'G-DZH02FJSGG',
  );
}
