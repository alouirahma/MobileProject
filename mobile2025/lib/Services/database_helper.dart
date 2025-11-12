import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const String _dbName = 'mobile2025.db';
  static const int _dbVersion = 5;

  static const String tableContents = 'contents';
  static const String tableUsers = 'users';
  static const String tableFavorites = 'favorites';
  static const String tableReviews = 'reviews';
  static const String tableReviewReports = 'review_reports';
  static const String tableReviewReactions = 'review_reactions';
  static const String tableNotifications = 'notifications';
  static const String tableEvents = 'events';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String databasesPath;
      if (Platform.isAndroid || Platform.isIOS) {
        databasesPath = await getDatabasesPath();
      } else {
        final directory = await getApplicationDocumentsDirectory();
        databasesPath = directory.path;
      }
      final path = join(databasesPath, _dbName);
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (_) {
      final fallBackPath = join(await getDatabasesPath(), _dbName);
      return await openDatabase(
        fallBackPath,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
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
        tags TEXT,
        uploadedBy TEXT,
        uploadDate TEXT,
        views INTEGER DEFAULT 0,
        likes INTEGER DEFAULT 0,
        isPublic INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableUsers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        avatar TEXT,
        bio TEXT,
        favoriteGenres TEXT,
        isPremium INTEGER DEFAULT 0,
        isModerator INTEGER DEFAULT 0
      )
    ''');

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

    await _createReviewTables(db);

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
        registeredUsers TEXT,
        FOREIGN KEY (contentId) REFERENCES $tableContents(id) ON DELETE SET NULL
      )
    ''');

    await _insertMockData(db);
  }

  Future<void> _createReviewTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableReviews (
        id TEXT PRIMARY KEY,
        contentId TEXT NOT NULL,
        userId TEXT NOT NULL,
        ratingType TEXT NOT NULL DEFAULT 'stars' CHECK (ratingType IN ('stars', 'thumbs', 'heart')),
        rating INTEGER NOT NULL,
        comment TEXT,
        date TEXT NOT NULL,
        isApproved INTEGER DEFAULT 1,
        parentId TEXT,
        reportedCount INTEGER DEFAULT 0,
        moderatedBy TEXT,
        moderationDate TEXT,
        moderationReason TEXT,
        likes INTEGER DEFAULT 0,
        dislikes INTEGER DEFAULT 0,
        FOREIGN KEY (contentId) REFERENCES $tableContents(id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE,
        FOREIGN KEY (parentId) REFERENCES $tableReviews(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableReviewReports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reviewId TEXT NOT NULL,
        userId TEXT NOT NULL,
        reason TEXT,
        date TEXT NOT NULL,
        UNIQUE(reviewId, userId),
        FOREIGN KEY (reviewId) REFERENCES $tableReviews(id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableReviewReactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reviewId TEXT NOT NULL,
        userId TEXT NOT NULL,
        reaction TEXT NOT NULL CHECK (reaction IN ('like', 'dislike')),
        date TEXT NOT NULL,
        UNIQUE(reviewId, userId),
        FOREIGN KEY (reviewId) REFERENCES $tableReviews(id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableNotifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        date TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        payload TEXT,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS $tableReviews');
      await db.execute('DROP TABLE IF EXISTS $tableReviewReports');
      await _createReviewTables(db);
    }
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS $tableReviewReports');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableReviewReports (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          reviewId TEXT NOT NULL,
          userId TEXT NOT NULL,
          reason TEXT,
          date TEXT NOT NULL,
          UNIQUE(reviewId, userId),
          FOREIGN KEY (reviewId) REFERENCES $tableReviews(id) ON DELETE CASCADE,
          FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
        )
      ''');
      final batch = db.batch();
      batch.execute("UPDATE $tableReviews SET ratingType = 'stars' WHERE ratingType IS NULL");
      batch.execute('UPDATE $tableReviews SET rating = CASE WHEN rating <= 0 THEN 1 ELSE rating END');
      await batch.commit(noResult: true);
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS $tableReviewReactions');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableReviewReactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          reviewId TEXT NOT NULL,
          userId TEXT NOT NULL,
          reaction TEXT NOT NULL CHECK (reaction IN ('like', 'dislike')),
          date TEXT NOT NULL,
          UNIQUE(reviewId, userId),
          FOREIGN KEY (reviewId) REFERENCES $tableReviews(id) ON DELETE CASCADE,
          FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
        )
      ''');

      final existingColumns = await db.rawQuery("PRAGMA table_info($tableUsers)");
      final hasModerator = existingColumns.any((row) => row['name'] == 'isModerator');
      if (!hasModerator) {
        await db.execute('ALTER TABLE $tableUsers ADD COLUMN isModerator INTEGER DEFAULT 0');
      }

      final notificationColumns = await db.rawQuery("PRAGMA table_info($tableNotifications)");
      if (notificationColumns.isEmpty) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableNotifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            date TEXT NOT NULL,
            isRead INTEGER DEFAULT 0,
            payload TEXT,
            FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
          )
        ''');
      } else {
        final hasPayload = notificationColumns.any((row) => row['name'] == 'payload');
        if (!hasPayload) {
          await db.execute('ALTER TABLE $tableNotifications ADD COLUMN payload TEXT');
        }
      }
    }

    if (oldVersion < 5) {
      final notificationColumns = await db.rawQuery("PRAGMA table_info($tableNotifications)");
      if (notificationColumns.isEmpty) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableNotifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            date TEXT NOT NULL,
            isRead INTEGER DEFAULT 0,
            payload TEXT,
            FOREIGN KEY (userId) REFERENCES $tableUsers(id) ON DELETE CASCADE
          )
        ''');
      }
    }
  }

  Future<void> _insertMockData(Database db) async {
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
      'isPublic': 1
    });

    await db.insert(tableUsers, {
      'id': 'u1',
      'name': 'Alice',
      'email': 'alice@example.com',
      'avatar': 'https://example.com/avatar1.jpg',
      'bio': 'Fan de musique',
      'favoriteGenres': jsonEncode(['Pop', 'Dance']),
      'isPremium': 1,
      'isModerator': 1,
    });
    await db.insert(tableUsers, {
      'id': 'u2',
      'name': 'Bruno',
      'email': 'bruno@example.com',
      'avatar': 'https://example.com/avatar2.jpg',
      'bio': 'Passionné de concerts live',
      'favoriteGenres': jsonEncode(['Rock', 'Electro']),
      'isPremium': 0,
      'isModerator': 0,
    });
    await db.insert(tableUsers, {
      'id': 'u3',
      'name': 'Chloe',
      'email': 'chloe@example.com',
      'avatar': 'https://example.com/avatar3.jpg',
      'bio': 'DJ amateur et grande collectionneuse de vinyles',
      'favoriteGenres': jsonEncode(['House', 'Pop']),
      'isPremium': 1,
      'isModerator': 0,
    });

    await db.insert(tableFavorites, {
      'userId': 'u1',
      'contentId': 'c1',
      'playlist': 'Mes Favoris',
      'addedAt': DateTime.now().toIso8601String(),
    });

    await db.insert(tableReviews, {
      'id': 'r1',
      'contentId': 'c1',
      'userId': 'u1',
      'ratingType': 'stars',
      'rating': 5,
      'comment': 'Super chanson !',
      'date': DateTime.now().toIso8601String(),
      'isApproved': 1,
      'likes': 10,
      'dislikes': 0,
    });
    await db.insert(tableReviews, {
      'id': 'r2',
      'contentId': 'c1',
      'userId': 'u2',
      'ratingType': 'thumbs',
      'rating': 1,
      'comment': 'Le refrain est addictif !',
      'date': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'isApproved': 1,
      'likes': 3,
      'dislikes': 0,
    });
    await db.insert(tableReviews, {
      'id': 'r3',
      'contentId': 'c1',
      'userId': 'u3',
      'ratingType': 'stars',
      'rating': 2,
      'comment': 'J\'aurais aimé un remix plus énergique.',
      'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'isApproved': 1,
      'likes': 1,
      'dislikes': 2,
    });

    await db.insert(tableReviewReactions, {
      'reviewId': 'r1',
      'userId': 'u2',
      'reaction': 'like',
      'date': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
    });
    await db.insert(tableReviewReactions, {
      'reviewId': 'r1',
      'userId': 'u3',
      'reaction': 'like',
      'date': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
    });
    await db.insert(tableReviewReactions, {
      'reviewId': 'r2',
      'userId': 'u1',
      'reaction': 'dislike',
      'date': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
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
      'registeredUsers': jsonEncode(['u1'])
    });
  }

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

  Future<List<Map<String, dynamic>>> getPublicContents() async {
    final db = await database;
    return db.query(tableContents, where: 'isPublic = ?', whereArgs: [1]);
  }

  Future<void> addContent(Map<String, dynamic> data) async {
    await insert(tableContents, data);
  }

  Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    final db = await database;
    return db.query(tableFavorites, where: 'userId = ?', whereArgs: [userId]);
  }

  Future<bool> toggleFavorite(String userId, String contentId, String? playlist) async {
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
      return false;
    } else {
      await insert(tableFavorites, {
        'userId': userId,
        'contentId': contentId,
        'playlist': playlist ?? 'Default',
        'addedAt': DateTime.now().toIso8601String(),
      });
      return true;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(tableUsers, where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return db.query(tableUsers, orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getContentReviews(
    String contentId, {
    String? ratingType,
    bool approvedOnly = true,
  }) async {
    final db = await database;
    String where = 'contentId = ?';
    final args = <dynamic>[contentId];

    if (approvedOnly) {
      where += ' AND isApproved = ?';
      args.add(1);
    }

    if (ratingType != null) {
      where += ' AND ratingType = ?';
      args.add(ratingType);
    }

    return db.query(
      tableReviews,
      where: where,
      whereArgs: args,
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getReviewReplies(String parentReviewId) async {
    final db = await database;
    return db.query(
      tableReviews,
      where: 'parentId = ? AND isApproved = ?',
      whereArgs: [parentReviewId, 1],
      orderBy: 'date ASC',
    );
  }

  Future<Map<String, dynamic>?> getReviewById(String reviewId) async {
    final db = await database;
    final result = await db.query(tableReviews, where: 'id = ?', whereArgs: [reviewId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserReviewForContent(String contentId, String userId) async {
    final db = await database;
    final result = await db.query(
      tableReviews,
      where: 'contentId = ? AND userId = ? AND parentId IS NULL',
      whereArgs: [contentId, userId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<String> addReview(Map<String, dynamic> reviewData) async {
    final db = await database;
    final reviewId = reviewData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    reviewData['id'] = reviewId;
    reviewData['ratingType'] ??= 'stars';
    reviewData['date'] = reviewData['date'] ?? DateTime.now().toIso8601String();
    await db.insert(tableReviews, reviewData, conflictAlgorithm: ConflictAlgorithm.replace);
    return reviewId;
  }

  Future<String> upsertReview(Map<String, dynamic> reviewData) async {
    final existing = await getUserReviewForContent(reviewData['contentId'], reviewData['userId']);
    if (existing != null) {
      await updateReview(existing['id'] as String, {
        'ratingType': reviewData['ratingType'],
        'rating': reviewData['rating'],
        'comment': reviewData['comment'],
        'date': DateTime.now().toIso8601String(),
      });
      return existing['id'] as String;
    }
    return addReview(reviewData);
  }

  Future<void> updateReview(String reviewId, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(tableReviews, updates, where: 'id = ?', whereArgs: [reviewId]);
  }

  Future<void> deleteReview(String reviewId) async {
    final db = await database;
    await db.delete(tableReviews, where: 'id = ?', whereArgs: [reviewId]);
  }

  Future<double> getAverageRating(String contentId, {String? ratingType}) async {
    final db = await database;
    String query = 'SELECT AVG(rating) as avg FROM $tableReviews WHERE contentId = ? AND isApproved = 1';
    final args = <dynamic>[contentId];
    if (ratingType != null) {
      query += ' AND ratingType = ?';
      args.add(ratingType);
    }
    final result = await db.rawQuery(query, args);
    final value = result.first['avg'] as num?;
    return value?.toDouble() ?? 0.0;
  }

  Future<int> getReviewCount(String contentId, {String? ratingType}) async {
    final db = await database;
    String where = 'contentId = ? AND isApproved = 1';
    final args = <dynamic>[contentId];
    if (ratingType != null) {
      where += ' AND ratingType = ?';
      args.add(ratingType);
    }
    final result = await db.query(tableReviews, where: where, whereArgs: args);
    return result.length;
  }

  Future<Map<String, int>> getRatingDistribution(String contentId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT ratingType, rating, COUNT(*) AS count
      FROM $tableReviews
      WHERE contentId = ? AND isApproved = 1
      GROUP BY ratingType, rating
    ''', [contentId]);

    final distribution = <String, int>{};
    for (final row in result) {
      final key = '${row['ratingType']}:${row['rating']}';
      distribution[key] = (row['count'] as int?) ?? 0;
    }
    return distribution;
  }

  Future<Map<String, String>> getUserReactionsForContent(String contentId, String userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT rr.reviewId, rr.reaction
      FROM $tableReviewReactions rr
      INNER JOIN $tableReviews r ON r.id = rr.reviewId
      WHERE r.contentId = ? AND rr.userId = ?
    ''', [contentId, userId]);

    final reactions = <String, String>{};
    for (final row in result) {
      final reviewId = row['reviewId'] as String?;
      final reaction = row['reaction'] as String?;
      if (reviewId != null && reaction != null) {
        reactions[reviewId] = reaction;
      }
    }
    return reactions;
  }

  Future<void> toggleReviewReaction(String reviewId, String userId, String reaction) async {
    final db = await database;
    final review = await getReviewById(reviewId);
    var likes = (review?['likes'] as int?) ?? 0;
    var dislikes = (review?['dislikes'] as int?) ?? 0;
    final reviewOwnerId = review?['userId'] as String?;

    final existing = await db.query(
      tableReviewReactions,
      where: 'reviewId = ? AND userId = ?',
      whereArgs: [reviewId, userId],
      limit: 1,
    );

    final now = DateTime.now().toIso8601String();
    if (existing.isNotEmpty) {
      final row = existing.first;
      final currentReaction = row['reaction'] as String?;
      if (currentReaction == reaction) {
        await db.delete(
          tableReviewReactions,
          where: 'reviewId = ? AND userId = ?',
          whereArgs: [reviewId, userId],
        );
        if (reaction == 'like' && likes > 0) {
          likes -= 1;
        } else if (reaction == 'dislike' && dislikes > 0) {
          dislikes -= 1;
        }
      } else {
        await db.update(
          tableReviewReactions,
          {
            'reaction': reaction,
            'date': now,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        if (currentReaction == 'like' && likes > 0) {
          likes -= 1;
        } else if (currentReaction == 'dislike' && dislikes > 0) {
          dislikes -= 1;
        }

        if (reaction == 'like') {
          likes += 1;
        } else if (reaction == 'dislike') {
          dislikes += 1;
        }
      }
    } else {
      await db.insert(
        tableReviewReactions,
        {
          'reviewId': reviewId,
          'userId': userId,
          'reaction': reaction,
          'date': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (reaction == 'like') {
        likes += 1;
      } else if (reaction == 'dislike') {
        dislikes += 1;
      }
    }

    await updateReview(reviewId, {'likes': likes, 'dislikes': dislikes});

    if (reviewOwnerId != null && reviewOwnerId != userId && reaction == 'like') {
      final reactorName = (await getUserById(userId))?['name'] as String? ?? 'Utilisateur $userId';
      final body = '$reactorName aime votre réponse.';
      await addNotification(reviewOwnerId, 'Nouvelle réaction', body, payload: '${review?['contentId']}:$reviewId');
    }
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final db = await database;
    final result = await db.query(tableUsers, where: 'id = ?', whereArgs: [userId], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> reportReview(String reviewId, String userId, {String? reason}) async {
    final db = await database;
    final existing = await db.query(
      tableReviewReports,
      where: 'reviewId = ? AND userId = ?',
      whereArgs: [reviewId, userId],
    );

    if (existing.isEmpty) {
      await db.insert(tableReviewReports, {
        'reviewId': reviewId,
        'userId': userId,
        'reason': reason,
        'date': DateTime.now().toIso8601String(),
      });

      final review = await getReviewById(reviewId);
      final currentCount = (review?['reportedCount'] as int?) ?? 0;
      await updateReview(reviewId, {'reportedCount': currentCount + 1});
    }
  }

  Future<List<Map<String, dynamic>>> getReportedReviews({int minReports = 1, String? ratingType, String? sortOption}) async {
    final db = await database;
    final whereClauses = <String>['reportedCount >= ?'];
    final whereArgs = <Object?>[minReports];

    if (ratingType != null) {
      whereClauses.add('ratingType = ?');
      whereArgs.add(ratingType);
    }

    String orderBy;
    switch (sortOption) {
      case 'date_asc':
        orderBy = 'date ASC';
        break;
      case 'date_desc':
        orderBy = 'date DESC';
        break;
      case 'reports_asc':
        orderBy = 'reportedCount ASC, date DESC';
        break;
      case 'likes_desc':
        orderBy = 'likes DESC, date DESC';
        break;
      case 'likes_asc':
        orderBy = 'likes ASC, date DESC';
        break;
      default:
        orderBy = 'reportedCount DESC, date DESC';
    }

    return db.query(
      tableReviews,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<List<Map<String, dynamic>>> getModeratedReviews({String? ratingType}) async {
    final db = await database;
    final whereClauses = <String>['isApproved = 0'];
    final whereArgs = <Object?>[];

    if (ratingType != null) {
      whereClauses.add('ratingType = ?');
      whereArgs.add(ratingType);
    }

    return db.query(
      tableReviews,
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'moderationDate DESC, date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getRejectedReviews() async {
    final db = await database;
    return db.query(
      tableReviews,
      where: 'isApproved = 0',
      orderBy: 'moderationDate DESC NULLS LAST, date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getModeratedHistory({int limit = 20}) async {
    final db = await database;
    return db.query(
      tableReviews,
      where: 'moderatedBy IS NOT NULL',
      orderBy: 'moderationDate DESC NULLS LAST, date DESC',
      limit: limit,
    );
  }

  Future<Map<String, int>> getModerationStats() async {
    final db = await database;
    final pending = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $tableReviews WHERE reportedCount > 0 AND isApproved = 1',
    )) ?? 0;
    final rejected = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $tableReviews WHERE isApproved = 0',
    )) ?? 0;
    final totalModerated = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM $tableReviews WHERE moderatedBy IS NOT NULL',
    )) ?? 0;

    return {
      'pending': pending,
      'rejected': rejected,
      'moderated': totalModerated,
    };
  }

  Future<void> moderateReview(String reviewId, String moderatorId, bool approve, {String? reason}) async {
    final db = await database;
    final newStatus = approve ? 1 : 0;

    await db.update(tableReviews, {
      'isApproved': newStatus,
      'moderatedBy': moderatorId,
      'moderationDate': DateTime.now().toIso8601String(),
      'moderationReason': reason,
      'reportedCount': 0,
    }, where: 'id = ?', whereArgs: [reviewId]);

    await db.delete(
      tableReviewReports,
      where: 'reviewId = ?',
      whereArgs: [reviewId],
    );
  }

  Future<void> restoreReview(String reviewId, String moderatorId) async {
    final db = await database;
    await db.update(tableReviews, {
      'isApproved': 1,
      'moderatedBy': moderatorId,
      'moderationDate': DateTime.now().toIso8601String(),
      'moderationReason': null,
      'reportedCount': 0,
    }, where: 'id = ?', whereArgs: [reviewId]);

    await db.delete(
      tableReviewReports,
      where: 'reviewId = ?',
      whereArgs: [reviewId],
    );
  }

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
    final event = await db.query(tableEvents, where: 'id = ?', whereArgs: [eventId]);
    if (event.isNotEmpty) {
      final users = List<String>.from(jsonDecode(event.first['registeredUsers'] as String));
      if (!users.contains(userId)) {
        users.add(userId);
        await update(tableEvents, {'registeredUsers': jsonEncode(users)}, eventId);
      }
    }
  }

  Future<void> addNotification(String userId, String title, String body, {String? payload}) async {
    final db = await database;
    await db.insert(tableNotifications, {
      'userId': userId,
      'title': title,
      'body': body,
      'date': DateTime.now().toIso8601String(),
      'isRead': 0,
      'payload': payload,
    });
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final db = await database;
    return db.query(
      tableNotifications,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications(String userId) async {
    final db = await database;
    return db.query(
      tableNotifications,
      where: 'userId = ? AND isRead = 0',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  Future<void> markNotificationsRead(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    await db.update(
      tableNotifications,
      {'isRead': 1},
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  Future<Map<String, dynamic>?> getNotificationById(int id) async {
    final db = await database;
    final result = await db.query(tableNotifications, where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getContentById(String contentId) async {
    final db = await database;
    final result = await db.query(tableContents, where: 'id = ?', whereArgs: [contentId], limit: 1);
    return result.isNotEmpty ? result.first : null;
  }
}