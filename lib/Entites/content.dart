// lib/Entities/content.dart
class Content {
  final String id;
  final String type;
  final String title;
  final int views;

  Content({
    required this.id,
    required this.type,
    required this.title,
    this.views = 0,
  });

  factory Content.fromMap(Map<String, dynamic> map) {
    return Content(
      id: map['id'],
      type: map['type'],
      title: map['title'],
      views: map['views'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'views': views,
      'isPublic': 1,
    };
  }
}