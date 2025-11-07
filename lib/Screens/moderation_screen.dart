// lib/Services/database_helper.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'mobile2025.db';
  static const int _dbVersion = 1;

  static const String tableContents = 'contents';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableContents (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        duration INTEGER,
        url TEXT,
        coverUrl TEXT,
        genre TEXT,
        tags TEXT,
        uploadDate TEXT,
        views INTEGER DEFAULT 0,
        likes INTEGER DEFAULT 0,
        isPublic INTEGER DEFAULT 1
      )
    ''');

    await db.insert(tableContents, {
      'id': 'c1',
      'type': 'audio',
      'title': 'Shape of You',
      'artist': 'Ed Sheeran',
      'duration': 235,
      'url': '',
      'coverUrl': '',
      'genre': 'Pop',
      'tags': jsonEncode(['pop', 'hit']),
      'uploadDate': '2025-01-01',
      'views': 1000,
      'likes': 500,
      'isPublic': 1,
    });
  }

  // --- CRUD ---
  Future<List<Map<String, dynamic>>> getPublicContents() async {
    final db = await database;
    return db.query(tableContents, where: 'isPublic = ?', whereArgs: [1]);
  }

  Future<void> addContent(Map<String, dynamic> data) async {
    await insert(tableContents, data);
  }

  Future<void> updateContent(String id, Map<String, dynamic> data) async {
    await update(tableContents, data, id);
  }

  Future<void> deleteContent(String id) async {
    await delete(tableContents, id);
  }

  // --- VUES & LIKES ---
  Future<void> incrementViews(String id) async {
    final db = await database;
    await db.rawUpdate('UPDATE $tableContents SET views = views + 1 WHERE id = ?', [id]);
  }

  Future<void> toggleLike(String id, bool isLiked) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $tableContents SET likes = likes ${isLiked ? '+' : '-'} 1 WHERE id = ?',
      [id],
    );
  }

  // --- GÉNÉRIQUE ---
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    return db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, String id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}