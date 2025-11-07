// lib/Screens/content_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Entites/content.dart';
import 'add_content_screen.dart';
import 'mini_player.dart';
import 'package:mobile2025/Services/audio_player_service.dart';
import 'dart:io';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});
  @override State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final _db = DatabaseHelper();
  final _player = AudioPlayerService();
  List<Content> _all = [];
  List<Content> _filtered = [];
  String _search = '';
  String _typeFilter = 'Tous';
  String _genreFilter = 'Tous';
  String _sort = 'date';
  final Set<String> _likedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _db.getPublicContents();
    final contents = data.map(Content.fromMap).toList();
    setState(() {
      _all = contents;
      _applyFilters();
    });
  }

  void _applyFilters() {
    var f = _all.where((c) {
      final s = _search.toLowerCase();
      return c.title.toLowerCase().contains(s) ||
          (c.artist?.toLowerCase().contains(s) ?? false) ||
          c.tags.any((t) => t.toLowerCase().contains(s));
    }).where((c) => _typeFilter == 'Tous' || c.type == _typeFilter.toLowerCase())
      .where((c) => _genreFilter == 'Tous' || c.genre == _genreFilter)
      .toList();

    f.sort((a, b) {
      if (_sort == 'date') return (b.uploadDate ?? '').compareTo(a.uploadDate ?? '');
      if (_sort == 'views') return b.views.compareTo(a.views);
      return b.likes.compareTo(a.likes);
    });

    setState(() => _filtered = f);
  }

  Future<void> _toggleLike(Content c) async {
    final wasLiked = _likedIds.contains(c.id);
    await _db.toggleLike(c.id, !wasLiked);
    setState(() {
      if (wasLiked) _likedIds.remove(c.id);
      else _likedIds.add(c.id);
      final updated = c.copyWith(likes: wasLiked ? c.likes - 1 : c.likes + 1);
      final i = _all.indexWhere((e) => e.id == c.id);
      if (i != -1) _all[i] = updated;
      final j = _filtered.indexWhere((e) => e.id == c.id);
      if (j != -1) _filtered[j] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contenus'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: Column(
        children: [
          _searchBar(),
          _filters(),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('Aucun contenu'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _card(_filtered[i]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: MiniPlayer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddContentScreen()));
          if (r == true) _load();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
      );

  Widget _filters() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _chip('Type', _typeFilter, ['Tous', 'audio', 'video', 'podcast']),
            const SizedBox(width: 8),
            _chip('Genre', _genreFilter, ['Tous', 'Pop', 'Rock', 'Hip-Hop', 'Jazz', 'Classique', 'Électro']),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.sort),
              label: Text('Trier: ${_sort == 'date' ? 'Date' : _sort == 'views' ? 'Vues' : 'Likes'}'),
              onPressed: () => setState(() {
                _sort = _sort == 'date' ? 'views' : _sort == 'views' ? 'likes' : 'date';
                _applyFilters();
              }),
            ),
          ],
        ),
      );

  Widget _chip(String l, String v, List<String> o) => FilterChip(
        label: Text('$l: $v'),
        selected: v != 'Tous',
        onSelected: (_) => showModalBottomSheet(
          context: context,
          builder: (_) => ListView(
            children: o.map((x) => ListTile(
              title: Text(x),
              onTap: () {
                setState(() {
                  if (l == 'Type') _typeFilter = x;
                  if (l == 'Genre') _genreFilter = x;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      );

  Widget _card(Content c) {
    final isLiked = _likedIds.contains(c.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              image: c.coverUrl != null && c.coverUrl!.isNotEmpty
                  ? DecorationImage(image: FileImage(File(c.coverUrl!)), fit: BoxFit.cover)
                  : null,
            ),
            child: c.coverUrl == null || c.coverUrl!.isEmpty ? const Icon(Icons.music_note) : null,
          ),
        ),
        title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${c.artist ?? 'Inconnu'} • ${c.views} vues'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isLiked ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey),
                onPressed: () => _toggleLike(c),
              ),
            ),
            Text('${c.likes}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            PopupMenuButton(
              onSelected: (v) {
                if (v == 'edit') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddContentScreen(content: c)))
                      .then((_) => _load());
                } else if (v == 'delete') {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Supprimer ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                        TextButton(
                          onPressed: () async {
                            await _db.deleteContent(c.id);
                            _load();
                            Navigator.pop(context);
                          },
                          child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Modifier')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Supprimer')])),
              ],
            ),
          ],
        ),
        onTap: () async {
          await _db.incrementViews(c.id);
          setState(() {
            final i = _filtered.indexWhere((e) => e.id == c.id);
            if (i != -1) _filtered[i] = c.copyWith(views: c.views + 1);
          });
          await _player.playContent(c);
        },
      ),
    );
  }
}