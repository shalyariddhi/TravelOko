import 'package:cloud_firestore/cloud_firestore.dart';

class SocialPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String content;
  final String imageUrl;
  final int likesCount;
  final List<String> likedBy;
  final int commentsCount;
  final DateTime createdAt;

  SocialPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.content,
    this.imageUrl = '',
    this.likesCount = 0,
    this.likedBy = const [],
    this.commentsCount = 0,
    required this.createdAt,
  });

  factory SocialPost.fromMap(Map<String, dynamic> data, String id) {
    return SocialPost(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Traveler',
      authorPhotoUrl: data['authorPhotoUrl'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likesCount: (data['likesCount'] ?? 0).toInt(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentsCount: (data['commentsCount'] ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'imageUrl': imageUrl,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'commentsCount': commentsCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
