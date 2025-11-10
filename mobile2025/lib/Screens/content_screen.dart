// lib/Screens/content_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Entites/content.dart';
import 'package:mobile2025/Screens/reviews_screen.dart';
import 'package:mobile2025/Screens/moderation_screen.dart';
import 'package:uuid/uuid.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Content> contents = [];
  Map<String, String> _users = {};
  Map<String, bool> _moderatorFlags = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadContents();
  }

  Future<void> _loadUsers() async {
    final data = await _db.getAllUsers();
    final mapped = <String, String>{};
    final moderators = <String, bool>{};
    for (final user in data) {
      final id = user['id'] as String?;
      if (id == null) continue;
      mapped[id] = user['name'] as String? ?? 'Utilisateur';
      moderators[id] = (user['isModerator'] as int? ?? 0) == 1;
    }
    setState(() {
      _users = mapped;
      _moderatorFlags = moderators;
      _currentUserId = mapped.keys.isNotEmpty ? mapped.keys.first : null;
    });
  }

  Future<void> _loadContents() async {
    final data = await _db.getPublicContents();
    setState(() {
      contents = data.map((e) => Content.fromMap(e)).toList();
    });
  }

  Future<void> _addContent() async {
    final titleCtrl = TextEditingController();
    final typeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter Contenu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Titre')),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type (audio/video)')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && typeCtrl.text.isNotEmpty) {
                final newContent = Content(
                  id: const Uuid().v4(),
                  title: titleCtrl.text,
                  type: typeCtrl.text,
                );
                await _db.insert(DatabaseHelper.tableContents, newContent.toMap());
                _loadContents();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenu'),
        actions: [
          if (_users.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentUserId,
                  icon: const Icon(Icons.person),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _currentUserId = value);
                  },
                  items: _users.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          if (_currentUserId != null && (_moderatorFlags[_currentUserId] ?? false))
            IconButton(
              tooltip: 'Modération',
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ModerationScreen(moderatorId: _currentUserId!),
                  ),
                );
              },
            ),
        ],
      ),
      body: contents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: contents.length,
              itemBuilder: (ctx, i) {
                final c = contents[i];
                return _buildContentCard(c);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContentCard(Content content) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getContentStats(content.id),
      builder: (context, snapshot) {
        final averageRating = snapshot.data?['averageRating'] ?? 0.0;
        final reviewCount = snapshot.data?['reviewCount'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(content.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${content.type} • ${content.views} vues'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (averageRating > 0) ...[
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (reviewCount > 0)
                      Text(
                        '$reviewCount avis',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.comment),
              onPressed: () {
                if (mounted && _currentUserId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ReviewsScreen(
                        content: content,
                        currentUserId: _currentUserId!,
                      ),
                    ),
                  );
                }
              },
              tooltip: 'Voir les avis',
            ),
            onTap: () {
              if (mounted && _currentUserId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ReviewsScreen(
                      content: content,
                      currentUserId: _currentUserId!,
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getContentStats(String contentId) async {
    final averageRating = await _db.getAverageRating(contentId);
    final reviewCount = await _db.getReviewCount(contentId);
    return {
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }
}