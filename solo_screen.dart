import 'dart:async';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../services/store.dart';
import 'quiz_widgets.dart';
import 'review_screen.dart';

/// Tek oyunculu oyunun ayar ekranı.
class SoloSetup extends StatefulWidget {
  final AuthService auth;
  const SoloSetup({super.key, required this.auth});
  @override
  State<SoloSetup> createState() => _SoloSetupState();
}

class _SoloSetupState extends State<SoloSetup> {
  final Set<String> picked = {Bank.courses.first.id};
  int count = 10;
  int seconds = 30;

  void _start() {
    if (picked.isEmpty) return;
    final pool = Bank.of(picked)..shuffle();
    final qs = pool.take(count).toList();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SoloPlay(auth: widget.auth, questions: qs, seconds: seconds),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tek başına çalış')),
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
        Text('Soru sayısı', style: Theme.of(context).textTheme.titleMedium),
        Wrap(spacing: 8, children: [
          for (final n in [10, 20, 50])
            ChoiceChip(label: Text('$n'), selected: count == n, onSelected: (_) => setState(() => count = n)),
        ]),
        const SizedBox(height: 16),
        Text('Süre (saniye, 0 = süresiz)', style: Theme.of(context).textTheme.titleMedium),
        Wrap(spacing: 8, children: [
          for (final n in [0, 20, 30, 40, 60])
            ChoiceChip(label: Text('$n'), selected: seconds == n, onSelected: (_) => setState(() => seconds = n)),
        ]),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _start, icon: const Icon(Icons.play_arrow), label: const Text('Başla')),
      ]),
    );
  }
}

class SoloPlay extends StatefulWidget {
  final AuthService auth;
  final List<Question> questions;
  final int seconds;
  const SoloPlay({super.key, required this.auth, required this.questions, required this.seconds});
  @override
  State<SoloPlay> createState() => _SoloPlayState();
}

class _SoloPlayState extends State<SoloPlay> {
  int idx = 0, score = 0, combo = 0, correct = 0;
  String? chosen;
  bool timedOut = false;
  late List<String> letters;
  Timer? _t;
  int left = 0;
  final List<MapEntry<Question, String?>> wrong = [];

  Question get q => widget.questions[idx];
  bool get resolved => chosen != null || timedOut;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    chosen = null;
    timedOut = false;
    letters = q.letters..shuffle();
    left = widget.seconds;
    _t?.cancel();
    if (widget.seconds > 0) {
      _t = Timer.periodic(const Duration(seconds: 1), (_) {
        if (resolved) return;
        setState(() => left--);
        if (left <= 0) _answer(null);
      });
    }
  }

  void _answer(String? letter) {
    if (resolved) return;
    final ok = letter == q.answer;
    setState(() {
      chosen = letter;
      timedOut = letter == null;
      if (ok) {
        combo++;
        correct++;
        final speed = widget.seconds > 0 ? (left / widget.seconds * 5).round() : 0;
        score += 10 + speed + (combo - 1).clamp(0, 5);
      } else {
        combo = 0;
        wrong.add(MapEntry(q, letter));
      }
    });
    Store.markWrong(q.id, !ok);
  }

  Future<void> _next() async {
    if (idx + 1 >= widget.questions.length) {
      _t?.cancel();
      Store.xp = Store.xp + score;
      if (widget.auth.online && widget.auth.signedIn) {
        try {
          await GameService().addWeekly(uid: widget.auth.uid, name: widget.auth.name, points: score);
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(
          auth: widget.auth,
          title: 'Oyun bitti',
          summary: 'Doğru: $correct / ${widget.questions.length}   ·   Puan: $score',
          wrong: wrong,
        ),
      ));
      return;
    }
    setState(() {
      idx++;
      _load();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${idx + 1} / ${widget.questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('$score puan${combo > 1 ? '  🔥$combo' : ''}')),
          ),
        ],
        bottom: widget.seconds > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: (left / widget.seconds).clamp(0, 1)),
              )
            : null,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (q.topic.isNotEmpty) Text(q.topic, style: Theme.of(context).textTheme.labelSmall),
        QuestionBody(q: q, letters: letters, chosen: chosen, reveal: resolved, onPick: _answer),
        if (!resolved)
          TextButton.icon(
            onPressed: () => _answer(null),
            icon: const Icon(Icons.visibility),
            label: const Text('Cevabı göster'),
          ),
        if (resolved) ...[
          const SizedBox(height: 8),
          LearnPanel(q: q, letters: letters),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _next,
            child: Text(idx + 1 >= widget.questions.length ? 'Bitir' : 'Sonraki'),
          ),
        ],
      ]),
    );
  }
}
