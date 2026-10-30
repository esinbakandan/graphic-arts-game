import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';
import 'auth_service.dart';

/// Soru hata bildirimleri. Kayıt `reports` koleksiyonuna yazılır; yönetici kimin bildirdiğini görür.
class FeedbackService {
  static AuthService? auth;
  static const maxImageBytes = 600 * 1024;

  static bool get canSend => (auth?.online ?? false) && (auth?.signedIn ?? false);

  static Future<void> submit({required Question q, String note = '', Uint8List? image}) async {
    final a = auth!;
    final u = a.user!;
    await FirebaseFirestore.instance.collection('reports').add({
      'qid': q.id,
      'course': q.courseId,
      'question': q.text,
      'answerKey': q.answer,
      'note': note.trim(),
      if (image != null) 'image': base64Encode(image),
      'userId': u.uid,
      'userName': a.name,
      'userEmail': u.email ?? '',
      'anonymous': u.isAnonymous,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> isAdmin() async {
    final a = auth;
    if (a == null || !a.online || !a.signedIn) return false;
    try {
      final d = await FirebaseFirestore.instance.collection('admins').doc(a.uid).get();
      return d.exists;
    } catch (_) {
      return false;
    }
  }
}
