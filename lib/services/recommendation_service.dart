import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social_post.dart';
import '../models/app_user.dart';
import 'session_intent_service.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SessionIntentService _sessionService = SessionIntentService();

  /// Calculates the Jaccard similarity between two sets of liked post IDs.
  double _calculateJaccardSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 0.0;
    final common = a.intersection(b).length;
    final total = a.union(b).length;
    return common / total;
  }

  /// Calculates cosine similarity between two embedding vectors.
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Fetches the current user data
  Future<AppUser?> _getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _firestore.collection('users').doc(user.uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(snap.data()!, snap.id);
  }

  /// Fetches collaborative recommendations (posts liked by similar users)
  Future<Set<String>> _getCollaborativeRecommendations(AppUser currentUser) async {
    final myLikes = currentUser.likedPostIds.toSet();
    if (myLikes.isEmpty) return {}; // Cold start: no likes yet

    // Fetch a sample of recently active users to find neighbors
    // We limit to 50 to prevent excessive Firestore reads on the client
    final activeUsersSnap = await _firestore
        .collection('users')
        .orderBy('lastActiveAt', descending: true)
        .limit(50)
        .get();

    Set<String> recommendedPostIds = {};

    for (var doc in activeUsersSnap.docs) {
      if (doc.id == currentUser.uid) continue;
      
      final neighborLikes = List<String>.from(doc.data()['likedPostIds'] ?? []).toSet();
      if (neighborLikes.isEmpty) continue;

      final similarity = _calculateJaccardSimilarity(myLikes, neighborLikes);
      
      // If the user is at least 30% similar in their likes
      if (similarity > 0.3) {
        recommendedPostIds.addAll(neighborLikes);
      }
    }

    // Remove posts the user has already liked
    recommendedPostIds.removeAll(myLikes);
    return recommendedPostIds;
  }

  /// Scores a post based on the combined ranking algorithm and A/B test weights
  double _scorePost({
    required SocialPost post,
    required AppUser currentUser,
    required Set<String> collaborativeIds,
  }) {
    // 1. Embedding Similarity (Long-term semantic preference)
    double similarity = _cosineSimilarity(currentUser.embedding, post.embedding);
    // If no embeddings exist, default to neutral
    if (currentUser.embedding.isEmpty || post.embedding.isEmpty) similarity = 0.5;

    // 2. Trending / Virality
    double trending = post.trendingScore;
    if (trending == 0 && post.likesCount > 0) {
       // Fallback trending calc if score not set by backend yet
       trending = (post.likesCount + (post.commentsCount * 2)).toDouble() / 10.0;
       if (trending > 1.0) trending = 1.0;
    }

    // 3. Collaborative Filtering (Community Wisdom)
    double collabBoost = collaborativeIds.contains(post.id) ? 1.0 : 0.0;

    // 4. Session Intent (Short-term context)
    double sessionIntent = _sessionService.getSessionBoost(post.hashtags);

    // 5. Social Boost (Are we following the author?)
    double socialBoost = currentUser.following.contains(post.authorId) ? 1.5 : 0.0;

    // A/B Testing: Apply different weights based on the experiment group
    if (currentUser.experimentGroup == 'A') {
      // Model A: Trending-heavy
      return (similarity * 0.2) + (trending * 0.5) + (collabBoost * 0.1) + (sessionIntent * 0.4) + socialBoost;
    } else {
      // Model B: Personalization-heavy (Embedding + Collab)
      return (similarity * 0.4) + (trending * 0.1) + (collabBoost * 0.3) + (sessionIntent * 0.4) + socialBoost;
    }
  }

  /// Returns a stream of the ranked social feed
  Stream<List<SocialPost>> getRankedFeed() {
    // We listen to the raw feed (e.g., last 100 posts)
    final rawFeedStream = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SocialPost.fromMap(d.data(), d.id)).toList());

    // We use asyncMap to inject the recommendation logic whenever the feed updates
    return rawFeedStream.asyncMap((posts) async {
      final currentUser = await _getCurrentAppUser();
      
      // Fallback to chronological if not logged in
      if (currentUser == null) return posts;

      // Fetch collaborative signals (which posts similar users liked)
      final collaborativeIds = await _getCollaborativeRecommendations(currentUser);

      // Score each post
      List<Map<String, dynamic>> scoredPosts = [];
      for (var post in posts) {
        final score = _scorePost(
          post: post,
          currentUser: currentUser,
          collaborativeIds: collaborativeIds,
        );
        scoredPosts.add({'post': post, 'score': score});
      }

      // Sort by score descending
      scoredPosts.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // Return the ranked list
      return scoredPosts.map((m) => m['post'] as SocialPost).toList();
    });
  }
}
