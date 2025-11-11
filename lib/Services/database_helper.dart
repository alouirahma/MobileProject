import 'dart:convert';
import 'package:mobile2025/Entites/User.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // --- Singleton ---
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // --- Configuration ---
  static const String _dbName = 'mobile2025.db';
  static const int _dbVersion = 3; //islem

  // --- Table Names (basé sur les 5 modules du doc) ---
  static const String tableContents = 'contents'; // Module 1: Gestion Contenu
  static const String tableUsers = 'users'; // Module 3: Utilisateur
  static const String tableFavorites = 'favorites'; // Module 2: Favoris
  static const String tableReviews = 'reviews'; // Module 4: Avis
  static const String tableEvents = 'events'; // Module 5: Événements

  // --- Accès à la base ---
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  //commande pour supp base
  //   await deleteDatabase(path);

  // --- Initialisation ---
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    //await deleteDatabase(path); // COMME ÇA
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // --- Création des tables (une par module) ---
  Future<void> _onCreate(Database db, int version) async {
    // Table Contenu (Module 1: Amine)
    await db.execute('''
      CREATE TABLE $tableContents (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL CHECK (type IN ('audio', 'video', 'podcast')),
        title TEXT NOT NULL,
        artist TEXT,
        duration INTEGER,
        url TEXT,
        coverUrl TEXT,
        genre TEXT,
        tags TEXT, -- JSON: ["pop", "dance"]
        uploadedBy TEXT,
        uploadDate TEXT,
        views INTEGER DEFAULT 0,
        likes INTEGER DEFAULT 0,
        isPublic INTEGER DEFAULT 1 -- BOOLEAN
      )
    ''');

    // Table Utilisateurs (Module 3: Islem)
    await db.execute('''
      CREATE TABLE $tableUsers (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        avatar TEXT,
        bio TEXT,
        favoriteGenres TEXT, -- JSON: ["Pop", "Dance"]
        isPremium INTEGER DEFAULT 0
      )
    ''');

    // Table Favoris (Module 2: Yosser)
    await db.execute('''
      CREATE TABLE $tableFavorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        contentId TEXT NOT NULL,
        playlist TEXT,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE,
        FOREIGN KEY (contentId) REFERENCES $tableContents(id) ON DELETE CASCADE,
        UNIQUE(userId, contentId, playlist)
      )
    ''');

    // Table Avis (Module 4: Ranim)
    await db.execute('''
      CREATE TABLE $tableReviews (
        id TEXT PRIMARY KEY,
        contentId TEXT NOT NULL,
        userId TEXT NOT NULL,
        rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
        comment TEXT,
        date TEXT NOT NULL,
        isApproved INTEGER DEFAULT 1,
        FOREIGN KEY (contentId) REFERENCES $tableContents(id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    // Table Événements (Module 5: Rahme)
    await db.execute('''
      CREATE TABLE $tableEvents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT,
        location TEXT,
        link TEXT,
        image TEXT,
        contentId TEXT,
        description TEXT,
        registeredUsers TEXT, -- JSON: ["u1", "u3"]
        FOREIGN KEY (contentId) REFERENCES $tableContents(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
  CREATE TABLE history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT NOT NULL,
    contentId TEXT NOT NULL,
    listenedAt TEXT NOT NULL,
    duration INTEGER,
    FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (contentId) REFERENCES contents(id) ON DELETE CASCADE
  )
''');

    // Insérer données mock pour tests
    await _insertMockData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ex: if (oldVersion < 3) { créer nouvelle table }
  }

  // --- Données mock (basées sur le doc) ---
  Future<void> _insertMockData(Database db) async {
    // Exemple Contenu
    // 1. UTILISATEUR D'ABORD
    await db.insert(tableUsers, {
      'id': 'u1',
      'username': 'alice_bob',
      'name': 'Alice',
      'email': 'alice@example.com',
      'password': 'alice123',
      'avatar': 'lib/assets/images/avatar1.png',
      'bio': 'Fan de musique',
      'favoriteGenres': jsonEncode(['Pop', 'Dance']),
      'isPremium': 1,
    });

    // 2. CONTENUS
    await db.insert(tableContents, {
      'id': 'c1',
      'type': 'audio',
      'title': 'Shape of You',
      'artist': 'Ed Sheeran',
      'duration': 235,
      'url': 'https://example.com/audio.mp3',
      'coverUrl': 'https://example.com/cover.jpg',
      'genre': 'Pop',
      'tags': jsonEncode(['pop', 'hit']),
      'uploadedBy': 'admin',
      'uploadDate': '2025-01-01',
      'views': 1000,
      'likes': 500,
      'isPublic': 1,
    });

    await db.insert(tableContents, {
      'id': 'c2',
      'type': 'audio',
      'title': 'Bohemian Rhapsody',
      'artist': 'Queen',
      'duration': 355,
      'coverUrl': 'https://example.com/queen.jpg',
      'genre': 'Rock',
      'isPublic': 1,
    });

    await db.insert(tableContents, {
      'id': 'c3',
      'type': 'audio',
      'title': 'Billie Jean',
      'artist': 'Michael Jackson',
      'duration': 294,
      'coverUrl': 'https://example.com/mj.jpg',
      'genre': 'Pop',
      'isPublic': 1,
    });

    await db.insert(tableContents, {
      'id': 'c4',
      'type': 'audio',
      'title': 'Smooth',
      'artist': 'Santana',
      'duration': 295,
      'coverUrl': 'https://example.com/santana.jpg',
      'genre': 'Rock',
      'isPublic': 1,
    });

    // 3. HISTORIQUE
    await db.insert('history', {
      'userId': 'u1',
      'contentId': 'c1',
      'listenedAt': DateTime.now()
          .subtract(Duration(minutes: 5))
          .toIso8601String(),
      'duration': 235,
    });

    await db.insert('history', {
      'userId': 'u1',
      'contentId': 'c2',
      'listenedAt': DateTime.now()
          .subtract(Duration(minutes: 15))
          .toIso8601String(),
      'duration': 355,
    });

    await db.insert('history', {
      'userId': 'u1',
      'contentId': 'c3',
      'listenedAt': DateTime.now()
          .subtract(Duration(minutes: 25))
          .toIso8601String(),
      'duration': 294,
    });

    await db.insert('history', {
      'userId': 'u1',
      'contentId': 'c4',
      'listenedAt': DateTime.now()
          .subtract(Duration(minutes: 35))
          .toIso8601String(),
      'duration': 295,
    });

    await db.insert('history', {
      'userId': 'u1',
      'contentId': 'c1',
      'listenedAt': '2025-11-05T14:20:00',
      'duration': 180,
    });

    // FAVORIS, AVIS, ÉVÉNEMENTS
    await db.insert(tableFavorites, {
      'userId': 'u1',
      'contentId': 'c1',
      'playlist': 'Mes Favoris',
      'addedAt': '2025-01-02',
    });

    await db.insert(tableReviews, {
      'id': 'r1',
      'contentId': 'c1',
      'userId': 'u1',
      'rating': 5,
      'comment': 'Super !',
      'date': '2025-01-03',
      'isApproved': 1,
    });

    await db.insert(tableEvents, {
      'id': 'e1',
      'title': 'Live Concert',
      'date': '2025-11-15',
      'time': '20:00',
      'location': 'Online',
      'link': 'https://example.com/live',
      'image': 'https://example.com/event.jpg',
      'contentId': 'c1',
      'description': 'Concert live',
      'registeredUsers': jsonEncode(['u1']),
    });
  }

  // --- Méthodes spécifiques par module (basé sur doc) ---

  // Module 1: Gestion Contenu (Amine)
  Future<List<Map<String, dynamic>>> getPublicContents() async {
    final db = await database;
    return db.query(tableContents, where: 'isPublic = ?', whereArgs: [1]);
  }

  Future<void> addContent(Map<String, dynamic> data) async {
    await insert(tableContents, data);
  }

  // Module 2: Favoris (Yosser)
  Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    final db = await database;
    return db.query(tableFavorites, where: 'userId = ?', whereArgs: [userId]);
  }

  Future<bool> toggleFavorite(
    String userId,
    String contentId,
    String? playlist,
  ) async {
    final db = await database;
    final exists = await db.query(
      tableFavorites,
      where: 'userId = ? AND contentId = ?',
      whereArgs: [userId, contentId],
    );
    if (exists.isNotEmpty) {
      await db.delete(
        tableFavorites,
        where: 'userId = ? AND contentId = ?',
        whereArgs: [userId, contentId],
      );
      return false; // Retiré
    } else {
      await insert(tableFavorites, {
        'userId': userId,
        'contentId': contentId,
        'playlist': playlist ?? 'Default',
        'addedAt': DateTime.now().toIso8601String(),
      });
      return true; // Ajouté
    }
  }

  // Module 3: Utilisateur (Islem)

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  //getbyusername
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      tableUsers,
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first : null;
  }
  // === AJOUTE CES MÉTHODES DANS DatabaseHelper (Islem) ===

  // Inscription
  Future<User?> registerUser({
    required String username,
    required String name,
    required String email,
    required String password,
    String? avatar,
  }) async {
    final db = await database;

    // Vérifier unicité
    final emailExists = await getUserByEmail(email);
    final usernameExists = await getUserByUsername(username);
    if (emailExists != null || usernameExists != null) return null;

    final id = 'u${DateTime.now().millisecondsSinceEpoch}';

    await insert(tableUsers, {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'password': password, // En clair pour dev (plus tard : BCrypt)
      'avatar': avatar,
      'bio': null,
      'favoriteGenres': jsonEncode([]),
      'isPremium': 0,
    });

    return User.fromMap(
      await db
          .query(tableUsers, where: 'id = ?', whereArgs: [id])
          .then((v) => v.first),
    );
  }

  // Connexion
  // Connexion par username
  Future<User?> signInByUsername(String username, String password) async {
    final db = await database;
    final result = await db.query(
      tableUsers,
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  // Mettre à jour avatar
  Future<bool> updateAvatar(String userId, String avatarPath) async {
    final db = await database;
    final rows = await db.update(
      tableUsers,
      {'avatar': avatarPath},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return rows > 0;
  }

  //add history islem
  Future<void> addListenHistory(
    String userId,
    String contentId,
    int duration,
  ) async {
    final db = await database;
    await db.insert('history', {
      'userId': userId,
      'contentId': contentId,
      'listenedAt': DateTime.now().toIso8601String(),
      'duration': duration,
    });
  }

  // Temps total écouté
  Future<int> getTotalListeningTime(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(duration) as total FROM history WHERE userId = ?',
      [userId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // Genre le plus écouté
  Future<String?> getTopGenre(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
    SELECT c.genre, SUM(h.duration) as total
    FROM history h
    JOIN contents c ON h.contentId = c.id
    WHERE h.userId = ?
    GROUP BY c.genre
    ORDER BY total DESC
    LIMIT 1
  ''',
      [userId],
    );
    return result.isNotEmpty ? result.first['genre'] as String? : null;
  }

  // Historique récent
  Future<List<Map<String, dynamic>>> getListeningHistory(String userId) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT h.*, c.title, c.artist, c.coverUrl
    FROM history h
    JOIN contents c ON h.contentId = c.id
    WHERE h.userId = ?
    ORDER BY h.listenedAt DESC
    LIMIT 10
  ''',
      [userId],
    );
  }
  // === AJOUTE ÇA (ÉTAPE 2) ===

  // 1. Pour le graphique donut (répartition par genre)
  Future<List<Map<String, dynamic>>> getGenreStats(String userId) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT c.genre, SUM(h.duration) as total
    FROM history h
    JOIN contents c ON h.contentId = c.id
    WHERE h.userId = ? AND c.genre IS NOT NULL
    GROUP BY c.genre
    ORDER BY total DESC
  ''',
      [userId],
    );
  }

  // 2. Historique avec username (pour afficher @alice_bob)
  Future<List<Map<String, dynamic>>> getListeningHistoryWithUsername(
    String userId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT 
      h.id,
      h.contentId,
      h.listenedAt,
      h.duration,
      c.title,
      c.artist,
      c.coverUrl,
      u.username
    FROM history h
    JOIN contents c ON h.contentId = c.id
    JOIN users u ON h.userId = u.id
    WHERE h.userId = ?
    ORDER BY h.listenedAt DESC
    LIMIT 20
  ''',
      [userId],
    );
  }

  // Module 4: Avis (Ranim)
  Future<List<Map<String, dynamic>>> getContentReviews(String contentId) async {
    final db = await database;
    return db.query(
      tableReviews,
      where: 'contentId = ? AND isApproved = ?',
      whereArgs: [contentId, 1],
    );
  }

  Future<double> getAverageRating(String contentId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(rating) as avg FROM $tableReviews WHERE contentId = ?',
      [contentId],
    );
    return result.first['avg'] as double? ?? 0.0;
  }

  // Module 5: Événements (Rahme)
  Future<List<Map<String, dynamic>>> getUpcomingEvents() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return db.query(
      tableEvents,
      where: 'date >= ?',
      whereArgs: [today],
      orderBy: 'date ASC',
    );
  }

  Future<void> registerUserToEvent(String eventId, String userId) async {
    final db = await database;
    final event = await db.query(
      tableEvents,
      where: 'id = ?',
      whereArgs: [eventId],
    );
    if (event.isNotEmpty) {
      List<String> users = jsonDecode(event.first['registeredUsers'] as String);
      if (!users.contains(userId)) {
        users.add(userId);
        await update(tableEvents, {
          'registeredUsers': jsonEncode(users),
        }, eventId);
      }
    }
  }

  // --- Méthodes génériques (conservées et adaptées) ---
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table);
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
