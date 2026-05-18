import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_loco/models/social_post.dart';

class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simple cosine similarity placeholder
  // In a real app, you would compute this via a cloud function or proper vector logic
  double _cosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.isEmpty || v2.isEmpty || v1.length != v2.length) return 0.5; // Neutral
    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;
    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      norm1 += v1[i] * v1[i];
      norm2 += v2[i] * v2[i];
    }
    if (norm1 == 0 || norm2 == 0) return 0;
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// Calculates the hybrid feed score for a given post based on
  /// similarity, trending score, whether the user follows the author,
  /// the post's age, and its boost status.
  double finalFeedScore({
    required double similarity,
    required double trending,
    required bool isFollowing,
    required int ageMs,
    required bool isBoosted,
    required int boostScore,
    required DateTime? boostExpiry,
    required Map<String, double> weights,
  }) {
    double score = 0;

    // Use dynamic weights learned from RLService
    final w1 = weights['w1'] ?? 0.4; // similarity
    final w2 = weights['w2'] ?? 0.3; // trending
    final w3 = weights['w3'] ?? 2.0; // following
    final w4 = weights['w4'] ?? 0.1; // recency

    score += similarity * w1;
    score += trending * w2;
    score += isFollowing ? w3 : 0;

    // Recency decay
    final recency = 1 / (1 + (ageMs / 1000000)); 
    score += recency * w4;

    // Apply Boost logic if active
    if (isBoosted && boostExpiry != null && DateTime.now().isBefore(boostExpiry)) {
      score += boostScore;
    }

    return score;
  }

  /// Fetches posts and ranks them for the current user's "For You" feed.
  /// Includes simple pagination via a DocumentSnapshot cursor.
  Future<List<SocialPost>> getForYouFeed({int limit = 20, DocumentSnapshot? startAfter}) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // Fetch user doc to get dynamic embeddings and weights
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final userEmbedding = (userData['embedding'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final feedWeights = (userData['feedWeights'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {
      'w1': 0.4, 'w2': 0.3, 'w3': 2.0, 'w4': 0.1
    };

    // 1. Fetch posts (paginated)
    Query query = _firestore.collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);
        
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final querySnapshot = await query.get();
    if (querySnapshot.docs.isEmpty) return [];

    // 2. Fetch following list
    final followingSnap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .get();
    final Set<String> following = followingSnap.docs.map((doc) => doc.id).toSet();

    // 3. Score and map posts
    final List<Map<String, dynamic>> scoredPosts = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final post = SocialPost.fromMap(data, doc.id);
      
      // Calculate age
      final ageMs = now - post.createdAt.millisecondsSinceEpoch;

      final isBoosted = data['isBoosted'] ?? false;
      final int boostScore = data['boostScore'] ?? 0;
      final DateTime? boostExpiry = (data['boostExpiry'] as Timestamp?)?.toDate();
      final double trendingScore = (data['trendingScore'] ?? 0.0).toDouble();
      
      // Calculate Cosine Similarity
      final similarityScore = _cosineSimilarity(userEmbedding, post.embedding);

      // Compute final score
      double score = finalFeedScore(
        similarity: similarityScore,
        trending: trendingScore,
        isFollowing: following.contains(post.authorId),
        ageMs: ageMs > 0 ? ageMs : 0,
        isBoosted: isBoosted,
        boostScore: boostScore,
        boostExpiry: boostExpiry,
        weights: feedWeights,
      );

      // Exploration logic: 10% chance to artificially bump a post to encourage diversity
      if (Random().nextDouble() < 0.1) {
        score += 50.0; // Random massive boost to skip the line
      }

      scoredPosts.add({
        'post': post,
        'score': score,
      });
    }

    // 4. Sort by highest score first
    scoredPosts.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return scoredPosts.map((m) => m['post'] as SocialPost).toList();
  }
}
