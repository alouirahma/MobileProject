// lib/Screens/content_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Entites/content.dart';
import 'package:uuid/uuid.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Content> contents = [];

  @override
  void initState() {
    super.initState();
    _loadContents();
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
      appBar: AppBar(title: const Text('Contenu')),
      body: contents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: contents.length,
              itemBuilder: (ctx, i) {
                final c = contents[i];
                return ListTile(
                  title: Text(c.title),
                  subtitle: Text('${c.type} • ${c.views} vues'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContent,
        child: const Icon(Icons.add),
      ),
    );
  }
}