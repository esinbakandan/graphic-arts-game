import 'package:flutter/material.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import 'login_screen.dart';
import 'room_screen.dart';

/// Birlikte oyna: oda kur, kodla katıl veya hızlı düello.
class LobbyScreen extends StatefulWidget {
  final AuthService auth;
  const LobbyScreen({super.key, required this.auth});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final svc = GameService();
  final code = TextEditingController();
  final Set<String> picked = {Bank.courses.first.id};
  bool busy = false;

  Future<void> _go(Future<String?> Function() f) async {
    if (!widget.auth.signedIn) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginScreen(auth: widget.auth)));
      if (!widget.auth.signedIn) return;
    }
    setState(() => busy = true);
    try {
      final c = await f();
      if (c == null) {
        _msg('Oda bulunamadı, dolu ya da oyun başlamış.');
      } else if (mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoomScreen(auth: widget.auth, code: c)));
      }
    } catch (e) {
      _msg('Hata: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final a = widget.auth;
    return Scaffold(
      appBar: AppBar(title: const Text('Birlikte oyna')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Dersler', style: Theme.of(context).textTheme.titleMedium),
        Wrap(spacing: 8, children: [
          for (final c in Bank.courses)
            FilterChip(
              label: Text(c.name),
              selected: picked.contains(c.id),
              onSelected: (v) => setState(() => v ? picked.add(c.id) : picked.remove(c.id)),
            ),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.groups),
          label: const Text('Oda kur (aynı anda, 2-8 kişi)'),
          onPressed: busy || picked.isEmpty
              ? null
              : () => _go(() => svc.createRoom(uid: a.uid, name: a.name, mode: 'live', courseIds: picked.toList())),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.sports_kabaddi),
          label: const Text('Hızlı düello (birebir)'),
          onPressed: busy || picked.isEmpty
              ? null
              : () => _go(() => svc.quickDuel(uid: a.uid, name: a.name, courseIds: picked.toList())),
        ),
        const Divider(height: 40),
        Text('Kodla katıl', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          maxLength: 5,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Oda kodu'),
        ),
        OutlinedButton(
          onPressed: busy
              ? null
              : () => _go(() async {
                    final c = code.text.trim().toUpperCase();
                    final ok = await svc.joinRoom(code: c, uid: a.uid, name: a.name);
                    return ok ? c : null;
                  }),
          child: const Text('Katıl'),
        ),
      ]),
    );
  }
}
