import 'package:flutter/material.dart';

import '../app_config.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/store.dart';
import '../services/feedback_service.dart';
import 'admin_screen.dart';
import 'leaderboard_screen.dart';
import 'lobby_screen.dart';
import 'login_screen.dart';
import 'review_screen.dart';
import 'solo_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService auth;
  const HomeScreen({super.key, required this.auth});

  void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final wrongQs = Store.wrong.map((id) => Bank.byId[id]).whereType<Question>().toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppConfig.appName),
            actions: [
              IconButton(
                tooltip: auth.signedIn ? 'Çıkış' : 'Giriş',
                icon: Icon(auth.signedIn ? Icons.logout : Icons.login),
                onPressed: () => auth.signedIn ? auth.signOut() : _push(context, LoginScreen(auth: auth)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(auth.signedIn ? auth.name : 'Giriş yapılmadı'),
                  subtitle: Text('Seviye ${Store.level} · ${Store.xp} XP · ${Bank.all.length} soru'),
                ),
              ),
              const SizedBox(height: 8),
              _big(context, Icons.menu_book, 'Tek başına çalış', 'Ders seç, süreli çöz, yanlışlarını öğren',
                  () => _push(context, SoloSetup(auth: auth))),
              _big(context, Icons.groups, 'Birlikte oyna', auth.online ? 'Aynı anda yarış veya birebir düello' : 'İnternet özellikleri kapalı',
                  auth.online ? () => _push(context, LobbyScreen(auth: auth)) : null),
              _big(context, Icons.emoji_events, 'Haftalık liste', 'Bu haftanın en iyileri',
                  auth.online ? () => _push(context, LeaderboardScreen(myUid: auth.uid)) : null),
              _big(
                context,
                Icons.school,
                'Yanlışlarım (${wrongQs.length})',
                'Yanlış yaptığın soruları tekrar çalış',
                wrongQs.isEmpty
                    ? null
                    : () => _push(
                          context,
                          SoloPlay(auth: auth, questions: ([...wrongQs]..shuffle()).take(20).toList(), seconds: 0),
                        ),
              ),
              if (auth.online && auth.signedIn)
                FutureBuilder<bool>(
                  future: FeedbackService.isAdmin(),
                  builder: (c, s) => s.data == true
                      ? _big(context, Icons.flag, 'Hata bildirimleri (yönetici)', 'Gelen bildirimler ve gönderenler',
                          () => _push(context, const AdminScreen()))
                      : const SizedBox.shrink(),
                ),
              if (!auth.online)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Not: Firebase ayarlanmadığı için çok oyunculu mod, giriş ve haftalık liste kapalı. '
                    'README\'deki 3. adımı yapınca açılır.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _big(BuildContext c, IconData i, String t, String s, VoidCallback? onTap) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(i, size: 32),
          title: Text(t, style: Theme.of(c).textTheme.titleMedium),
          subtitle: Text(s),
          enabled: onTap != null,
          onTap: onTap,
        ),
      );
}
