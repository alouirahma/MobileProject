// lib/Screens/add_content_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Entites/content.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class AddContentScreen extends StatefulWidget {
  final Content? content;
  const AddContentScreen({super.key, this.content});

  @override
  State<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  late TextEditingController _title, _artist, _duration, _tags;
  String _type = 'audio', _genre = 'Pop';
  String? _cover, _file, _fileName;
  bool _public = true;

  final types = ['audio', 'video', 'podcast'];
  final genres = ['Pop', 'Rock', 'Hip-Hop', 'Jazz', 'Classique', 'Électro', 'Autre'];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.content?.title ?? '');
    _artist = TextEditingController(text: widget.content?.artist ?? '');
    _duration = TextEditingController(text: widget.content?.duration?.toString() ?? '');
    _tags = TextEditingController(text: widget.content?.tags.join(', ') ?? '');
    _type = widget.content?.type ?? 'audio';
    _genre = widget.content?.genre ?? 'Pop';
    _cover = widget.content?.coverUrl;
    _file = widget.content?.url;
    _fileName = _file?.split('/').last;
    _public = widget.content?.isPublic ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _duration.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (p != null) setState(() => _cover = p.path);
  }

  Future<void> _pickFile() async {
    final t = _type == 'audio' ? FileType.audio : FileType.video;
    final r = await FilePicker.platform.pickFiles(type: t);
    if (r != null) {
      setState(() {
        _file = r.files.single.path;
        _fileName = r.files.single.name;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final c = Content(
      id: widget.content?.id ?? const Uuid().v4(),
      type: _type,
      title: _title.text.trim(),
      artist: _artist.text.trim().isEmpty ? null : _artist.text.trim(),
      duration: int.tryParse(_duration.text),
      url: _file,
      coverUrl: _cover,
      genre: _genre,
      tags: _tags.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      isPublic: _public,
    );

    if (widget.content == null) {
      await _db.addContent(c.toMap());
    } else {
      await _db.updateContent(c.id, c.toMap());
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content == null ? 'Ajouter' : 'Modifier'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickCover,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[200],
                    image: _cover != null
                        ? DecorationImage(image: FileImage(File(_cover!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _cover == null
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 48), Text('Couverture')])
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Titre *', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _artist, decoration: const InputDecoration(labelText: 'Artiste', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField<String>(value: _type, items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _type = v!), decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: DropdownButtonFormField<String>(value: _genre, items: genres.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _genre = v!), decoration: const InputDecoration(labelText: 'Genre', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Durée (s)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                controller: _tags,
                decoration: InputDecoration(
                  labelText: 'Tags',
                  border: const OutlineInputBorder(),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.auto_awesome),
                    onSelected: (t) => _tags.text = _tags.text.isEmpty ? t : '${_tags.text}, $t',
                    itemBuilder: (_) => ['hit', 'nouveau', 'viral'].map((t) => PopupMenuItem(value: t, child: Text('#$t'))).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(leading: const Icon(Icons.attach_file), title: Text(_fileName ?? 'Aucun fichier'), trailing: const Icon(Icons.folder_open), onTap: _pickFile),
              SwitchListTile(title: const Text('Public'), value: _public, onChanged: (v) => setState(() => _public = v)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 56)),
                child: const Text('SAUVEGARDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}