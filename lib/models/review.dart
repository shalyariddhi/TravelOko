import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  Review({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      rating: map['rating'] ?? 5,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
