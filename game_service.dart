import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_config.dart';
import '../models.dart';

/// Çok oyunculu oda mantığı (Cloud Firestore).
///
/// rooms/{kod}                 -> oda durumu (host, mod, sorular, sıra, süre)
/// rooms/{kod}/players/{uid}   -> oyuncu: ad, puan, cevaplar
/// weekly/{haftaId}/scores/{uid} -> haftalık genel liste
class GameService {
  final _db = FirebaseFirestore.instance;
  static final _rnd = Random();

  static String weekId([DateTime? d]) {
    d ??= DateTime.now().toUtc();
    final thursday = d.add(Duration(days: 4 - (d.weekday)));
    final jan1 = DateTime.utc(thursday.year, 1, 1);
    final week = ((thursday.difference(jan1).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  String _code() {
    const c = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(5, (_) => c[_rnd.nextInt(c.length)]).join();
  }

  DocumentReference<Map<String, dynamic>> room(String code) => _db.collection('rooms').doc(code);

  /// mode: 'live' (2+ kişi aynı anda) veya 'duel' (birebir)
  Future<String> createRoom({
    required String uid,
    required String name,
    required String mode,
    required List<String> courseIds,
    bool isPublic = false,
  }) async {
    final pool = Bank.of(courseIds)..shuffle();
    final ids = pool.take(AppConfig.liveQuestions).map((q) => q.id).toList();
    final code = _code();
    await room(code).set({
      'host': uid,
      'mode': mode,
      'courses': courseIds,
      'qids': ids,
      'status': 'lobby',
      'qIndex': 0,
      'startedAt': null,
      'public': isPublic,
      'max': mode == 'duel' ? 2 : 8,
      'created': FieldValue.serverTimestamp(),
    });
    await joinRoom(code: code, uid: uid, name: name);
    return code;
  }

  Future<bool> joinRoom({required String code, required String uid, required String name}) async {
    final snap = await room(code).get();
    if (!snap.exists) return false;
    final d = snap.data()!;
    if (d['status'] != 'lobby') return false;
    final count = (await room(code).collection('players').get()).size;
    final already = (await room(code).collection('players').doc(uid).get()).exists;
    if (!already && count >= (d['max'] as int)) return false;
    await room(code).collection('players').doc(uid).set({
      'name': name,
      'score': 0,
      'correct': 0,
      'ans': <String, dynamic>{},
      'joined': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  /// Birebir düello için hızlı eşleşme: bekleyen açık oda varsa katılır, yoksa yeni açar.
  Future<String> quickDuel({
    required String uid,
    required String name,
    required List<String> courseIds,
  }) async {
    final q = await _db
        .collection('rooms')
        .where('mode', isEqualTo: 'duel')
        .where('status', isEqualTo: 'lobby')
        .where('public', isEqualTo: true)
        .limit(5)
        .get();
    for (final d in q.docs) {
      if (d.data()['host'] == uid) continue;
      if (await joinRoom(code: d.id, uid: uid, name: name)) return d.id;
    }
    return createRoom(uid: uid, name: name, mode: 'duel', courseIds: courseIds, isPublic: true);
  }

  Future<void> start(String code) => room(code).update({
        'status': 'playing',
        'qIndex': 0,
        'startedAt': FieldValue.serverTimestamp(),
      });

  Future<void> nextQuestion(String code, int next, int total) {
    if (next >= total) return room(code).update({'status': 'done'});
    return room(code).update({'qIndex': next, 'startedAt': FieldValue.serverTimestamp()});
  }

  /// Cevabı yazar; puanı hesaplayıp oyuncu belgesine ekler.
  Future<int> submitAnswer({
    required String code,
    required String uid,
    required int index,
    required String letter,
    required bool correct,
    required double remainingFraction,
  }) async {
    final gain = correct ? 100 + (100 * remainingFraction.clamp(0, 1)).round() : 0;
    await room(code).collection('players').doc(uid).update({
      'ans.$index': letter,
      'score': FieldValue.increment(gain),
      'correct': FieldValue.increment(correct ? 1 : 0),
    });
    return gain;
  }

  Future<void> leave(String code, String uid) async {
    await room(code).collection('players').doc(uid).delete();
  }

  // ---- haftalık liste ----
  Future<void> addWeekly({required String uid, required String name, required int points}) async {
    if (points <= 0) return;
    await _db.collection('weekly').doc(weekId()).collection('scores').doc(uid).set({
      'name': name,
      'score': FieldValue.increment(points),
      'updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> weeklyTop() => _db
      .collection('weekly')
      .doc(weekId())
      .collection('scores')
      .orderBy('score', descending: true)
      .limit(20)
      .snapshots();
}
