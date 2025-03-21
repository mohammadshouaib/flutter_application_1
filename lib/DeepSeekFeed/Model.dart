class User {
  final String id;
  final String name;
  final String profileImageUrl;

  User({required this.id, required this.name, required this.profileImageUrl});
}

class Comment {
  final String id;
  final String text;
  final User user;
  final DateTime timestamp;

  Comment({required this.id, required this.text, required this.user, required this.timestamp});
}

class Post {
  final String id;
  final User user;
  final String routeImageUrl;
  final String description;
  final DateTime timestamp;
  final List<Comment> comments;
  final int likes;

  Post({
    required this.id,
    required this.user,
    required this.routeImageUrl,
    required this.description,
    required this.timestamp,
    this.comments = const [],
    this.likes = 0,
  });
}