// lib/Entities/content.dart
import 'dart:convert';

class Content {
  final String id;
  final String type;
  final String title;
  final String? artist;
  final int? duration;
  final String? url;
  final String? coverUrl;
  final String? genre;
  final List<String> tags;
  final String? uploadDate;
  final int views;
  final int likes;
  final bool isPublic;

  Content({
    required this.id,
    required this.type,
    required this.title,
    this.artist,
    this.duration,
    this.url,
    this.coverUrl,
    this.genre,
    this.tags = const [],
    this.uploadDate,
    this.views = 0,
    this.likes = 0,
    this.isPublic = true,
  });

  factory Content.fromMap(Map<String, dynamic> map) {
    return Content(
      id: map['id'],
      type: map['type'],
      title: map['title'],
      artist: map['artist'],
      duration: map['duration'],
      url: map['url'],
      coverUrl: map['coverUrl'],
      genre: map['genre'],
      tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'])) : [],
      uploadDate: map['uploadDate'],
      views: map['views'] ?? 0,
      likes: map['likes'] ?? 0,
      isPublic: (map['isPublic'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'artist': artist,
      'duration': duration,
      'url': url,
      'coverUrl': coverUrl,
      'genre': genre,
      'tags': jsonEncode(tags),
      'uploadDate': uploadDate ?? DateTime.now().toIso8601String(),
      'views': views,
      'likes': likes,
      'isPublic': isPublic ? 1 : 0,
    };
  }

  Content copyWith({int? views, int? likes}) {
    return Content(
      id: id,
      type: type,
      title: title,
      artist: artist,
      duration: duration,
      url: url,
      coverUrl: coverUrl,
      genre: genre,
      tags: tags,
      uploadDate: uploadDate,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      isPublic: isPublic,
    );
  }
}