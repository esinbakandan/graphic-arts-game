// Firebase ayarları. Aşağıdaki "BURAYA_..." yazan yerleri Firebase Console >
// Proje ayarları > Uygulamalarınız bölümündeki değerlerle değiştir (README, 3. adım).
// Değişmezse uygulama çevrimdışı tek oyunculu çalışır.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final o = kIsWeb
        ? web
        : (defaultTargetPlatform == TargetPlatform.android ? android : null);
    if (o == null || o.apiKey.startsWith('BURAYA')) {
      throw UnsupportedError('Firebase ayarlanmadı.');
    }
    return o;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'BURAYA_WEB_API_KEY',
    appId: 'BURAYA_WEB_APP_ID',
    messagingSenderId: 'BURAYA_SENDER_ID',
    projectId: 'BURAYA_PROJECT_ID',
    authDomain: 'BURAYA_PROJECT_ID.firebaseapp.com',
    storageBucket: 'BURAYA_PROJECT_ID.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'BURAYA_ANDROID_API_KEY',
    appId: 'BURAYA_ANDROID_APP_ID',
    messagingSenderId: 'BURAYA_SENDER_ID',
    projectId: 'BURAYA_PROJECT_ID',
    storageBucket: 'BURAYA_PROJECT_ID.firebasestorage.app',
  );
}
