import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/store.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;
  const LoginScreen({super.key, required this.auth});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nick = TextEditingController(text: Store.nickname);
  bool busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => busy = true);
    try {
      await f();
      if (mounted && widget.auth.signedIn) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Giriş yapılamadı: $e')));
      }
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (!widget.auth.online)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('Bu sürümde internet bağlantılı özellikler kapalı (Firebase ayarlanmamış veya '
                  'masaüstü sürümü). Tek oyunculu mod çalışır. Çok oyunculu için web sürümünü veya '
                  'Android uygulamasını kullanın.'),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: busy || !widget.auth.online ? null : () => _run(widget.auth.signInGoogle),
          icon: const Icon(Icons.g_mobiledata, size: 28),
          label: const Text('Google ile giriş'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: busy || !widget.auth.online ? null : () => _run(widget.auth.signInFacebook),
          icon: const Icon(Icons.facebook),
          label: const Text('Facebook ile giriş'),
        ),
        const Divider(height: 40),
        Text('Ya da takma adla katıl', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: nick,
          maxLength: 20,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Takma ad'),
        ),
        FilledButton(
          onPressed: busy
              ? null
              : () => _run(() => widget.auth.signInGuest(nick.text.isEmpty ? 'Oyuncu' : nick.text)),
          child: const Text('Devam et'),
        ),
      ]),
    );
  }
}
