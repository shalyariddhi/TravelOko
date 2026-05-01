import 'package:cloud_firestore/cloud_firestore.dart';

class UserReview {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhotoUrl;
  final String revieweeId;
  final double rating;
  final String text;
  final DateTime createdAt;

  UserReview({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerPhotoUrl,
    required this.revieweeId,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  factory UserReview.fromMap(Map<String, dynamic> data, String id) {
    return UserReview(
      id: id,
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? 'Traveler',
      reviewerPhotoUrl: data['reviewerPhotoUrl'] ?? '',
      revieweeId: data['revieweeId'] ?? '',
      rating: (data['rating'] ?? 5.0).toDouble(),
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'revieweeId': revieweeId,
      'rating': rating,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
