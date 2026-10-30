import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'firebase_options.dart';
import 'models.dart';
import 'services/feedback_service.dart';
import 'services/auth_service.dart';
import 'services/store.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Bank.load();
  await Store.init();
  var online = false;
  // Firebase yalnızca Android, iOS ve web'de desteklenir; masaüstü sürümü tek oyunculu çalışır.
  final platformOk = kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (platformOk) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      online = true;
    } catch (e) {
      debugPrint('Firebase kapalı: $e');
    }
  }
  final auth = AuthService(online: online);
  FeedbackService.auth = auth;
  runApp(GameApp(auth: auth));
}

class GameApp extends StatelessWidget {
  final AuthService auth;
  const GameApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1F5FFF),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6F95FF),
        brightness: Brightness.dark,
      ),
      home: HomeScreen(auth: auth),
    );
  }
}
