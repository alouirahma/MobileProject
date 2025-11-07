// lib/Screens/admin_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Entites/content.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});
  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final _db = DatabaseHelper();
  int totalContents = 0;
  int totalViews = 0;
  int totalLikes = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final contents = await _db.getPublicContents();

    int views = 0;
    int likes = 0;

    for (var c in contents) {
      final int? v = c['views'] as int?;
      final int? l = c['likes'] as int?;
      views += v ?? 0;
      likes += l ?? 0;
    }

    setState(() {
      totalContents = contents.length;
      totalViews = views;
      totalLikes = likes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Admin'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _statCard('Contenus', totalContents, Icons.library_music),
            _statCard('Vues totales', totalViews, Icons.remove_red_eye),
            _statCard('Likes totaux', totalLikes, Icons.favorite),
            const Divider(height: 32),
            ElevatedButton.icon(
              onPressed: _showTop10,
              icon: const Icon(Icons.trending_up),
              label: const Text('Top 10'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, IconData icon) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          '$value',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showTop10() async {
    final contents = await _db.getPublicContents();
    final List<Map<String, dynamic>> sorted = List.from(contents)
      ..sort((a, b) {
        final int va = a['views'] as int? ?? 0;
        final int vb = b['views'] as int? ?? 0;
        return vb.compareTo(va);
      });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Top 10 des contenus'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sorted.take(10).length,
            itemBuilder: (ctx, i) {
              final c = Content.fromMap(sorted[i]);
              return ListTile(
                leading: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                title: Text(c.title),
                subtitle: Text('${c.views} vues • ${c.likes} likes'),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}