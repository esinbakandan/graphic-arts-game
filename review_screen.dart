import 'package:flutter/material.dart';

import '../models.dart';
import '../services/auth_service.dart';
import 'quiz_widgets.dart';
import 'solo_screen.dart';

/// Oyun sonu: sonuç özeti + "yanlışlardan öğrenme turu".
class ResultScreen extends StatelessWidget {
  final AuthService auth;
  final String title, summary;
  final List<MapEntry<Question, String?>> wrong;
  const ResultScreen({
    super.key,
    required this.auth,
    required this.title,
    required this.summary,
    required this.wrong,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(summary, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (wrong.isEmpty) const Text('Hiç yanlışın yok, harika! 🎉'),
        if (wrong.isNotEmpty) ...[
          FilledButton.icon(
            icon: const Icon(Icons.school),
            label: Text('Yanlışlardan öğren (${wrong.length})'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => LearningRound(items: wrong)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Yanlışları tekrar çöz'),
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => SoloPlay(
                auth: auth,
                questions: wrong.map((e) => e.key).toList()..shuffle(),
                seconds: 0,
              ),
            )),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Ana sayfa')),
      ]),
    );
  }
}

/// Yanlış yapılan soruları doğru cevap, açıklama ve çeviriyle sırayla gösterir.
class LearningRound extends StatelessWidget {
  final List<MapEntry<Question, String?>> items;
  const LearningRound({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yanlışlardan öğren')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 32),
        itemBuilder: (_, i) {
          final q = items[i].key;
          final letters = q.letters;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            QuestionBody(q: q, letters: letters, chosen: items[i].value, reveal: true),
            LearnPanel(q: q, letters: letters),
          ]);
        },
      ),
    );
  }
}
