import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/feedback_service.dart';

/// "Hata bildir" penceresi: ekran görüntüsü (isteğe bağlı) + açıklama (isteğe bağlı).
class FeedbackSheet extends StatefulWidget {
  final Question q;
  const FeedbackSheet({super.key, required this.q});

  static Future<void> open(BuildContext context, Question q) {
    if (!FeedbackService.canSend) {
      return showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Giriş gerekli'),
          content: const Text('Hata bildirebilmek için internete bağlı olmalı ve giriş yapmış olmalısın (misafir girişi de olur).'),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam'))],
        ),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FeedbackSheet(q: q),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final note = TextEditingController();
  Uint8List? img;
  bool busy = false;
  String? err;

  Future<void> pick() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 60);
      if (f == null) return;
      final b = await f.readAsBytes();
      if (b.length > FeedbackService.maxImageBytes) {
        setState(() => err = 'Görsel çok büyük, daha küçük bir ekran görüntüsü seç.');
        return;
      }
      setState(() {
        img = b;
        err = null;
      });
    } catch (e) {
      setState(() => err = 'Görsel seçilemedi.');
    }
  }

  Future<void> send() async {
    setState(() {
      busy = true;
      err = null;
    });
    try {
      await FeedbackService.submit(q: widget.q, note: note.text, image: img);
      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.pop();
      await showDialog(
        context: nav.context,
        builder: (c) => AlertDialog(
          content: const Text(
            'Geri bildirimin için teşekkürler! En kısa sürede inceleyip gerekli düzeltmeleri yapacağız.\n\nİyi çalışmalar! 😇',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam'))],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => err = 'Gönderilemedi, internetini kontrol edip tekrar dene.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hata bildir', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(widget.q.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : pick,
              icon: const Icon(Icons.image_outlined),
              label: Text(img == null ? 'Ekran görüntüsü ekle' : 'Görseli değiştir'),
            ),
            if (img != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(img!, height: 140, fit: BoxFit.cover)),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 4,
              maxLength: 600,
              decoration: const InputDecoration(
                labelText: 'Açıklama (isteğe bağlı)',
                border: OutlineInputBorder(),
              ),
            ),
            if (err != null) Text(err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: busy ? null : send,
              icon: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}
