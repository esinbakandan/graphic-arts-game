import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_config.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import 'quiz_widgets.dart';
import 'review_screen.dart';

/// Oda: bekleme salonu -> canlı oyun -> sonuç. Tüm oyuncular aynı soruyu aynı anda görür.
class RoomScreen extends StatefulWidget {
  final AuthService auth;
  final String code;
  const RoomScreen({super.key, required this.auth, required this.code});
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final svc = GameService();
  Timer? _tick;
  DateTime now = DateTime.now();

  // host ilerletme durumu
  int _resolvedIdx = -1;
  DateTime? _resolvedAt;
  bool _scoredWeekly = false;

  // bu cihazın seçtiği şık (anlık geri bildirim için)
  final Map<int, String> mine = {};
  List<String>? _letters;
  int _lettersFor = -1;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 300), (_) => setState(() => now = DateTime.now()));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: svc.room(widget.code).snapshots(),
      builder: (c, rs) {
        if (rs.hasError) return _scaffold(Center(child: Text('Bağlantı hatası: ${rs.error}')));
        if (!rs.hasData) return _scaffold(const Center(child: CircularProgressIndicator()));
        final room = rs.data!.data();
        if (room == null) return _scaffold(const Center(child: Text('Oda kapandı.')));
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: svc.room(widget.code).collection('players').snapshots(),
          builder: (c, ps) {
            final players = ps.data?.docs ?? [];
            switch (room['status']) {
              case 'playing':
                return _playing(room, players);
              case 'done':
                return _done(room, players);
              default:
                return _lobby(room, players);
            }
          },
        );
      },
    );
  }

  Widget _scaffold(Widget body, {String? title, List<Widget>? actions}) => Scaffold(
        appBar: AppBar(title: Text(title ?? 'Oda ${widget.code}'), actions: actions),
        body: body,
      );

  // ---------- bekleme salonu ----------
  Widget _lobby(Map<String, dynamic> room, List<QueryDocumentSnapshot<Map<String, dynamic>>> players) {
    final isHost = room['host'] == widget.auth.uid;
    final duel = room['mode'] == 'duel';
    final need = duel ? 2 : 2;
    return _scaffold(
      ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: Column(children: [
            Text(duel ? 'Birebir düello' : 'Aynı anda oyun', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(widget.code, style: Theme.of(context).textTheme.displayMedium),
            const Text('Arkadaşlarına bu kodu ver'),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Oyuncular (${players.length}/${room['max']})', style: Theme.of(context).textTheme.titleSmall),
        for (final p in players)
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(p.data()['name']?.toString() ?? 'Oyuncu'),
            trailing: p.id == room['host'] ? const Chip(label: Text('Kurucu')) : null,
          ),
        const SizedBox(height: 16),
        if (isHost)
          FilledButton.icon(
            onPressed: players.length >= need ? () => svc.start(widget.code) : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(players.length >= need ? 'Oyunu başlat' : 'En az $need oyuncu gerekli'),
          )
        else
          const Center(child: Text('Kurucunun oyunu başlatması bekleniyor…')),
        TextButton(
          onPressed: () async {
            await svc.leave(widget.code, widget.auth.uid);
            if (mounted) Navigator.of(context).pop();
          },
          child: const Text('Odadan ayrıl'),
        ),
      ]),
    );
  }

  // ---------- canlı oyun ----------
  Widget _playing(Map<String, dynamic> room, List<QueryDocumentSnapshot<Map<String, dynamic>>> players) {
    final qids = (room['qids'] as List).cast<String>();
    final idx = room['qIndex'] as int;
    final q = Bank.byId[qids[idx]]!;
    final started = (room['startedAt'] as Timestamp?)?.toDate() ?? now;
    final total = AppConfig.liveSeconds;
    final elapsed = now.difference(started).inMilliseconds / 1000.0;
    final left = (total - elapsed).clamp(0, total).toDouble();
    final timeUp = left <= 0;
    if (_lettersFor != idx) {
      _letters = q.letters..shuffle();
      _lettersFor = idx;
    }
    final letters = _letters!;

    final me = players.where((p) => p.id == widget.auth.uid).toList();
    final myAns = me.isEmpty ? null : ((me.first.data()['ans'] as Map?)?['$idx'] as String?);
    final answeredCount = players.where((p) => (p.data()['ans'] as Map?)?.containsKey('$idx') == true).length;
    final resolved = myAns != null || timeUp;

    // kurucu soruyu ilerletir: herkes cevapladı veya süre bitti, sonra 3 sn sonuç göster
    if (room['host'] == widget.auth.uid) {
      final everyone = players.isNotEmpty && answeredCount >= players.length;
      if ((everyone || timeUp) && _resolvedIdx != idx) {
        _resolvedIdx = idx;
        _resolvedAt = now;
      }
      if (_resolvedIdx == idx && _resolvedAt != null && now.difference(_resolvedAt!).inSeconds >= 3) {
        _resolvedAt = null;
        svc.nextQuestion(widget.code, idx + 1, qids.length);
      }
    }

    final sorted = [...players]..sort((a, b) => (b.data()['score'] as int).compareTo(a.data()['score'] as int));
    final everyoneAnswered = answeredCount >= players.length || timeUp;

    return _scaffold(
      ListView(padding: const EdgeInsets.all(16), children: [
        LinearProgressIndicator(value: left / total),
        const SizedBox(height: 4),
        Text('Soru ${idx + 1} / ${qids.length}  ·  ${left.ceil()} sn  ·  cevaplayan $answeredCount/${players.length}',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        QuestionBody(
          q: q,
          letters: letters,
          chosen: myAns ?? mine[idx],
          reveal: everyoneAnswered && resolved,
          onPick: timeUp || myAns != null
              ? null
              : (l) async {
                  setState(() => mine[idx] = l);
                  await svc.submitAnswer(
                    code: widget.code,
                    uid: widget.auth.uid,
                    index: idx,
                    letter: l,
                    correct: l == q.answer,
                    remainingFraction: left / total,
                  );
                },
        ),
        if (resolved && !everyoneAnswered)
          const Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Diğer oyuncular bekleniyor…'))),
        if (everyoneAnswered) LearnPanel(q: q, letters: letters),
        const Divider(height: 24),
        Text('Sıralama', style: Theme.of(context).textTheme.titleSmall),
        for (var i = 0; i < sorted.length; i++)
          ListTile(
            dense: true,
            leading: CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
            title: Text(sorted[i].data()['name']?.toString() ?? ''),
            trailing: Text('${sorted[i].data()['score']}'),
          ),
      ]),
      title: 'Oda ${widget.code}',
    );
  }

  // ---------- sonuç ----------
  Widget _done(Map<String, dynamic> room, List<QueryDocumentSnapshot<Map<String, dynamic>>> players) {
    final qids = (room['qids'] as List).cast<String>();
    final sorted = [...players]..sort((a, b) => (b.data()['score'] as int).compareTo(a.data()['score'] as int));
    final me = players.where((p) => p.id == widget.auth.uid).toList();
    final ans = me.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(me.first.data()['ans'] as Map? ?? {});
    final wrong = <MapEntry<Question, String?>>[];
    for (var i = 0; i < qids.length; i++) {
      final q = Bank.byId[qids[i]]!;
      final a = ans['$i'] as String?;
      if (a != q.answer) wrong.add(MapEntry(q, a));
    }
    if (!_scoredWeekly && me.isNotEmpty) {
      _scoredWeekly = true;
      svc.addWeekly(uid: widget.auth.uid, name: widget.auth.name, points: me.first.data()['score'] as int);
    }
    final winner = sorted.isEmpty ? null : sorted.first;
    final draw = sorted.length > 1 && sorted[0].data()['score'] == sorted[1].data()['score'];
    return _scaffold(
      ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: Text(
            draw ? 'Berabere!' : '🏆 ${winner?.data()['name'] ?? ''} kazandı',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < sorted.length; i++)
          ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(sorted[i].data()['name']?.toString() ?? ''),
            subtitle: Text('Doğru: ${sorted[i].data()['correct']} / ${qids.length}'),
            trailing: Text('${sorted[i].data()['score']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 12),
        if (wrong.isNotEmpty)
          FilledButton.icon(
            icon: const Icon(Icons.school),
            label: Text('Yanlışlardan öğren (${wrong.length})'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LearningRound(items: wrong))),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: const Text('Ana sayfa'),
        ),
      ]),
      title: 'Sonuç',
    );
  }
}
