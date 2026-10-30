import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/game_service.dart';

class LeaderboardScreen extends StatelessWidget {
  final String myUid;
  const LeaderboardScreen({super.key, required this.myUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Haftalık liste · ${GameService.weekId()}')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: GameService().weeklyTop(),
        builder: (c, s) {
          if (s.hasError) return Center(child: Text('Liste açılamadı: ${s.error}'));
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final docs = s.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Bu hafta henüz puan yok. İlk sen ol!'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i];
              final me = d.id == myUid;
              return ListTile(
                tileColor: me ? Theme.of(context).colorScheme.primaryContainer : null,
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(d.data()['name']?.toString() ?? 'Oyuncu'),
                trailing: Text('${d.data()['score'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}
