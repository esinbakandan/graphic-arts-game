import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Vocab {
  final String word;
  final String tr;
  Vocab(this.word, this.tr);
}

class Course {
  final String id;
  final String name;
  Course(this.id, this.name);
}

class Question {
  final String id, courseId, text, answer;
  final Map<String, String> options;
  final String topic, explanation, textTr, note;
  final Map<String, String> optionsTr;
  final List<Vocab> vocab;

  Question({
    required this.id,
    required this.courseId,
    required this.text,
    required this.options,
    required this.answer,
    this.topic = '',
    this.explanation = '',
    this.textTr = '',
    this.note = '',
    this.optionsTr = const {},
    this.vocab = const [],
  });

  factory Question.fromJson(Map<String, dynamic> j) {
    Map<String, String> sm(dynamic m) =>
        (m as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v.toString()));
    return Question(
      id: j['id'] as String,
      courseId: j['c'] as String,
      text: j['q'] as String,
      options: sm(j['o']),
      answer: j['a'] as String,
      topic: (j['t'] ?? '') as String,
      explanation: (j['e'] ?? '') as String,
      textTr: (j['qt'] ?? '') as String,
      note: (j['n'] ?? '') as String,
      optionsTr: sm(j['ot']),
      vocab: ((j['v'] as List?) ?? [])
          .map((e) => Vocab(e['w'].toString(), (e['tr'] ?? '').toString()))
          .toList(),
    );
  }

  List<String> get letters => (options.keys.toList()..sort());
}

class Bank {
  static List<Course> courses = [];
  static List<Question> all = [];
  static final Map<String, Question> byId = {};

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/questions.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    courses = (j['courses'] as List).map((e) => Course(e['id'], e['name'])).toList();
    all = (j['questions'] as List).map((e) => Question.fromJson(e)).toList();
    for (final q in all) {
      byId[q.id] = q;
    }
  }

  static List<Question> of(Iterable<String> courseIds) =>
      all.where((q) => courseIds.contains(q.courseId)).toList();

  static String courseName(String id) =>
      courses.firstWhere((c) => c.id == id, orElse: () => Course(id, id)).name;
}
