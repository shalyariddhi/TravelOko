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
  final List<double> embedding;
  final List<String> hashtags;
  final double trendingScore;

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
    this.embedding = const [],
    this.hashtags = const [],
    this.trendingScore = 0.0,
  });

  factory SocialPost.fromMap(Map<String, dynamic> data, String id) {
    return SocialPost(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Traveler',
      authorPhotoUrl: (data['authorPhotoUrl']?.toString().contains('pravatar') ?? false)
          ? 'https://api.dicebear.com/9.x/avataaars/png?seed=${data['authorId']}'
          : data['authorPhotoUrl'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likesCount: (data['likesCount'] ?? 0).toInt(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentsCount: (data['commentsCount'] ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      embedding: (data['embedding'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      hashtags: List<String>.from(data['hashtags'] ?? []),
      trendingScore: (data['trendingScore'] ?? 0.0).toDouble(),
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
      'embedding': embedding,
      'hashtags': hashtags,
      'trendingScore': trendingScore,
    };
  }
}
