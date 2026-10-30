import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazda saklanan tek oyunculu ilerleme (XP, yanlış yapılan sorular, seri).
class Store {
  static late SharedPreferences _p;
  static Future<void> init() async => _p = await SharedPreferences.getInstance();

  static int get xp => _p.getInt('xp') ?? 0;
  static set xp(int v) => _p.setInt('xp', v);

  static String get nickname => _p.getString('nick') ?? '';
  static set nickname(String v) => _p.setString('nick', v);

  static Set<String> get wrong =>
      (jsonDecode(_p.getString('wrong') ?? '[]') as List).cast<String>().toSet();
  static void markWrong(String id, bool isWrong) {
    final s = wrong;
    isWrong ? s.add(id) : s.remove(id);
    _p.setString('wrong', jsonEncode(s.toList()));
  }

  static int get level => 1 + xp ~/ 500;
}
