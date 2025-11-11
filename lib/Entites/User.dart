import 'dart:convert';

class User {
  final String id;
  final String username;
  final String name;
  final String email;
  final String? avatar;
  final String? bio;
  final List<String> favoriteGenres;
  final bool isPremium;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    this.avatar,
    this.bio,
    required this.favoriteGenres,
    required this.isPremium,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      avatar: map['avatar'] as String?,
      bio: map['bio'] as String?,
      favoriteGenres: map['favoriteGenres'] != null
          ? List<String>.from(jsonDecode(map['favoriteGenres']))
          : [],
      isPremium: (map['isPremium'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'avatar': avatar,
      'bio': bio,
      'favoriteGenres': jsonEncode(favoriteGenres),
      'isPremium': isPremium ? 1 : 0,
    };
  }
}
