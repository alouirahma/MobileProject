// lib/Entites/review.dart
class Review {
  final String id;
  final String contentId;
  final String userId;
  final String ratingType; // 'stars', 'thumbs', 'heart'
  final int rating; // 1-5 pour stars, 1-2 pour thumbs (1=up, 2=down), 1 pour heart
  final String? comment;
  final String date;
  final bool isApproved;
  final String? parentId; // Pour les réponses
  final int reportedCount;
  final String? moderatedBy;
  final String? moderationDate;
  final String? moderationReason;
  final int likes;
  final int dislikes;

  Review({
    required this.id,
    required this.contentId,
    required this.userId,
    this.ratingType = 'stars',
    required this.rating,
    this.comment,
    required this.date,
    this.isApproved = true,
    this.parentId,
    this.reportedCount = 0,
    this.moderatedBy,
    this.moderationDate,
    this.moderationReason,
    this.likes = 0,
    this.dislikes = 0,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      contentId: map['contentId'],
      userId: map['userId'],
      ratingType: map['ratingType'] ?? 'stars',
      rating: map['rating'],
      comment: map['comment'],
      date: map['date'],
      isApproved: (map['isApproved'] as int?) == 1,
      parentId: map['parentId'],
      reportedCount: map['reportedCount'] ?? 0,
      moderatedBy: map['moderatedBy'],
      moderationDate: map['moderationDate'],
      moderationReason: map['moderationReason'],
      likes: map['likes'] ?? 0,
      dislikes: map['dislikes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contentId': contentId,
      'userId': userId,
      'ratingType': ratingType,
      'rating': rating,
      'comment': comment,
      'date': date,
      'isApproved': isApproved ? 1 : 0,
      'parentId': parentId,
      'reportedCount': reportedCount,
      'moderatedBy': moderatedBy,
      'moderationDate': moderationDate,
      'moderationReason': moderationReason,
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  bool get isReply => parentId != null;
}


