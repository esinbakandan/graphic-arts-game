import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app_config.dart';
import 'store.dart';

/// Giriş yönetimi: Google, Facebook veya takma adla misafir girişi.
/// [online] false ise (Firebase ayarlanmamış / masaüstü) yalnızca yerel mod çalışır.
class AuthService extends ChangeNotifier {
  final bool online;
  AuthService({required this.online}) {
    if (online) {
      FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
    }
  }

  User? get user => online ? FirebaseAuth.instance.currentUser : null;
  bool get signedIn => user != null;
  String get uid => user?.uid ?? 'local';

  String get name {
    final u = user;
    if (u != null && (u.displayName ?? '').isNotEmpty) return u.displayName!;
    if (Store.nickname.isNotEmpty) return Store.nickname;
    return 'Oyuncu';
  }

  Future<void> signInGoogle() async {
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } else {
      final g = GoogleSignIn(
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      );
      final acc = await g.signIn();
      if (acc == null) return;
      final a = await acc.authentication;
      await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(accessToken: a.accessToken, idToken: a.idToken),
      );
    }
    notifyListeners();
  }

  Future<void> signInFacebook() async {
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(FacebookAuthProvider());
    } else {
      final r = await FacebookAuth.instance.login();
      if (r.status != LoginStatus.success || r.accessToken == null) return;
      await FirebaseAuth.instance.signInWithCredential(
        FacebookAuthProvider.credential(r.accessToken!.tokenString),
      );
    }
    notifyListeners();
  }

  /// Hesapsız giriş: takma ad + anonim Firebase oturumu.
  Future<void> signInGuest(String nick) async {
    Store.nickname = nick.trim();
    if (online && FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    if (online) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
    }
    notifyListeners();
  }
}
