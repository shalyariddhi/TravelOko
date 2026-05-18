import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Tracks a unique view for a given post.
  /// Uses a Cloud Function to handle the increment transactionally.
  Future<void> incrementUniqueView(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final callable = _functions.httpsCallable('incrementUniqueView');
      await callable.call({
        'postId': postId,
        'userId': user.uid,
      });
    } catch (e) {
      // Fallback: If cloud function fails or is not yet deployed, try direct firestore write
      // In production, security rules should enforce this logic instead of client-side
      try {
        final viewRef = _firestore.collection('posts').doc(postId).collection('views').doc(user.uid);
        final doc = await viewRef.get();
        if (!doc.exists) {
          await _firestore.runTransaction((transaction) async {
            transaction.set(viewRef, {'viewedAt': FieldValue.serverTimestamp()});
            transaction.update(_firestore.collection('posts').doc(postId), {
              'viewsCount': FieldValue.increment(1)
            });
          });
        }
      } catch (innerE) {
        // Ignore view count errors to avoid interrupting user experience
      }
    }
  }

  /// Calculates the engagement rate for a post.
  double calculateEngagementRate(Map<String, dynamic> postData) {
    final int views = postData['viewsCount'] ?? 1;
    final int likes = postData['likesCount'] ?? 0;
    final int comments = postData['commentsCount'] ?? 0;
    final int saves = postData['savesCount'] ?? 0;
    final int shares = postData['sharesCount'] ?? 0;

    final int totalEngagement = likes + comments + saves + shares;
    return views > 0 ? (totalEngagement / views) : 0.0;
  }

  /// Tracks an outbound affiliate link click.
  /// Writes to `affiliate_clicks` collection for revenue analytics.
  /// [hotelName] – the hotel/property name displayed to the user.
  /// [vendor] – the affiliate partner name (e.g. 'Booking.com').
  /// [affiliateUrl] – the full URL that was opened.
  Future<void> trackAffiliateClick({
    required String hotelName,
    required String vendor,
    required String affiliateUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('affiliate_clicks').add({
        'userId': user?.uid ?? 'anonymous',
        'hotelName': hotelName,
        'vendor': vendor,
        'url': affiliateUrl,
        'clickedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      });
      debugPrint('[Analytics] Affiliate click tracked: $hotelName → $vendor');
    } catch (e) {
      // Non-fatal: don't interrupt the user's booking flow.
      debugPrint('[Analytics] Failed to track affiliate click: $e');
    }
  }
}
