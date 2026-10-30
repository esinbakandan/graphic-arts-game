import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Yalnızca yönetici: gelen hata bildirimleri ve kimin gönderdiği.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance.collection('reports').orderBy('createdAt', descending: true).limit(200);
    return Scaffold(
      appBar: AppBar(title: const Text('Hata bildirimleri')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (c, s) {
          if (s.hasError) return Center(child: Text('Hata: ${s.error}'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final docs = s.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Henüz bildirim yok.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final d = docs[i];
              final m = d.data();
              final done = m['status'] == 'done';
              final ts = (m['createdAt'] as Timestamp?)?.toDate();
              return Card(
                color: done ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${m['userName']}  ·  ${m['userEmail'] == '' ? (m['anonymous'] == true ? 'misafir' : '-') : m['userEmail']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('uid: ${m['userId']}${ts == null ? '' : '  ·  $ts'}', style: Theme.of(context).textTheme.bodySmall),
                    const Divider(),
                    Text('Soru ${m['qid']} (${m['course']}), anahtar: ${m['answerKey']}', style: Theme.of(context).textTheme.labelMedium),
                    Text('${m['question']}'),
                    if ((m['note'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Not: ${m['note']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                    if (m['image'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => Dialog(child: InteractiveViewer(child: Image.memory(base64Decode(m['image'])))),
                          ),
                          child: Image.memory(base64Decode(m['image']), height: 160),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => d.reference.update({'status': done ? 'new' : 'done'}),
                        child: Text(done ? 'Yeniden aç' : 'Çözüldü'),
                      ),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
