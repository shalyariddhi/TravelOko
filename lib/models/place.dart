import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double avgRating;
  final int reviewsCount;
  final double popularityScore;
  final bool isHidden;
  final int? createdAtMs; // milliseconds since epoch for score calculation

  Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.avgRating = 0.0,
    this.reviewsCount = 0,
    this.popularityScore = 0.0,
    this.isHidden = false,
    this.createdAtMs,
  });

  factory Place.fromMap(Map<String, dynamic> map, String id) {
    int? createdMs;
    if (map['createdAt'] is Timestamp) {
      createdMs = (map['createdAt'] as Timestamp).millisecondsSinceEpoch;
    } else if (map['createdAt'] is int) {
      createdMs = map['createdAt'] as int;
    }

    return Place(
      id: id,
      name: map['name'] ?? 'Unknown',
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      avgRating: (map['avgRating'] ?? 0).toDouble(),
      reviewsCount: map['reviewsCount'] ?? 0,
      popularityScore: (map['popularityScore'] ?? 0).toDouble(),
      isHidden: map['isHidden'] ?? false,
      createdAtMs: createdMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'avgRating': avgRating,
      'reviewsCount': reviewsCount,
      'popularityScore': popularityScore,
      'isHidden': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
