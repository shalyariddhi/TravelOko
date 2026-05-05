import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/app_user.dart';
import '../models/destination.dart';
import '../models/social_post.dart';
import '../models/post_comment.dart';
import '../models/user_review.dart';
import '../data/mock_data.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // serverClientId = the Web OAuth client from google-services.json (client_type: 3)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '675905775251-afn5ce9u8jidnv8o59n91m77rq4aopkp.apps.googleusercontent.com',
  );

  // ─────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password,
      {String displayName = '', String gender = 'unknown'}) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = result.user;
      if (user != null) {
        // Create Firestore user document on signup
        await _firestore.collection('users').doc(user.uid).set({
          'displayName': displayName.isEmpty ? email.split('@')[0] : displayName,
          'email': email,
          'photoUrl': '',
          'bio': '',
          'tripsCount': 0,
          'followersCount': 0,
          'badges': [],
          'verifiedScore': 0,
          'gender': gender,
          'dateOfBirth': '',
          'locality': '',
          'isIdentityVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      debugPrint('Sign up error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─────────────────────────────────────────
  // GOOGLE SIGN-IN
  // ─────────────────────────────────────────

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        // Create/update Firestore profile if new user
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'displayName': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'bio': '',
            'tripsCount': 0,
            'followersCount': 0,
            'badges': [],
            'verifiedScore': 80,
            'gender': 'unknown', // User can update this in profile later
            'dateOfBirth': '',
            'locality': '',
            'isIdentityVerified': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return user;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────
  // USER PROFILE
  // ─────────────────────────────────────────

  Stream<AppUser?> getUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) =>
            doc.exists ? AppUser.fromMap(doc.data()!, doc.id) : null)
        .handleError((e) {
      debugPrint('Error streaming user profile: $e');
    });
  }

  Future<void> updateUserProfile(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(user.toMap());
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<void> acceptTerms() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'hasAcceptedTerms': true,
      });
    }
  }

  Future<void> followUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Add target to current user's following list
    await _firestore.collection('users').doc(user.uid).update({
      'following': FieldValue.arrayUnion([targetUserId])
    });

    // Increment target user's followers count
    await _firestore.collection('users').doc(targetUserId).update({
      'followersCount': FieldValue.increment(1)
    });
  }

  Future<void> unfollowUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'following': FieldValue.arrayRemove([targetUserId])
    });

    await _firestore.collection('users').doc(targetUserId).update({
      'followersCount': FieldValue.increment(-1)
    });
  }

  // ─────────────────────────────────────────
  // TRIPS
  // ─────────────────────────────────────────

  /// Live stream of all trips, optionally filtered
  Stream<List<Trip>> getTrips({
    int? maxBudget,
    int? maxDuration,
    bool? onlyGirls,
  }) async* {
    final user = _auth.currentUser;
    String userGender = 'unknown';

    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        userGender = doc.data()?['gender'] ?? 'unknown';
      } catch (_) {}
    }

    Query<Map<String, dynamic>> query =
        _firestore.collection('trips').orderBy('startDate');

    if (onlyGirls == true) {
      query = query.where('isOnlyGirls', isEqualTo: true);
    }

    yield* query.snapshots().map((snap) {
      final trips =
          snap.docs.map((d) => Trip.fromMap(d.data(), d.id)).toList();

      // Client-side filter for budget, duration, and gender
      return trips.where((t) {
        // Enforce gender filter: if it's an only girls trip, user MUST be female
        if (t.isOnlyGirls && userGender != 'female') return false;

        final budgetOk = maxBudget == null || t.budget <= maxBudget;
        final durationOk = maxDuration == null || t.durationDays <= maxDuration;
        return budgetOk && durationOk;
      }).toList();
    }).handleError((e) {
      debugPrint('Error fetching trips: $e');
      return <Trip>[];
    });
  }

  Future<void> toggleWishlist(String tripId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final docRef = _firestore.collection('users').doc(user.uid);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) return;
      
      final wishlist = List<String>.from(snap.data()?['wishlist'] ?? []);
      if (wishlist.contains(tripId)) {
        wishlist.remove(tripId);
      } else {
        wishlist.add(tripId);
      }
      txn.update(docRef, {'wishlist': wishlist});
    });
  }

  /// Live stream of feed trips (Hosted by user, followed users, or exclusive)
  Stream<List<Trip>> getFeedTrips(AppUser currentUser) async* {
    Query<Map<String, dynamic>> query =
        _firestore.collection('trips').orderBy('startDate');

    yield* query.snapshots().map((snap) {
      final trips =
          snap.docs.map((d) => Trip.fromMap(d.data(), d.id)).toList();

      return trips.where((t) {
        if (t.isOnlyGirls && currentUser.gender != 'female') return false;
        
        bool isHosted = t.organizerId == currentUser.uid;
        bool isFollowed = currentUser.following.contains(t.organizerId);
        bool isExclusive = t.isExclusive;
        
        return isHosted || isFollowed || isExclusive;
      }).toList();
    }).handleError((e) {
      debugPrint('Error fetching feed trips: $e');
      return <Trip>[];
    });
  }

  /// Search users by display name (prefix match)
  Future<List<AppUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      // Return all users when no query
      final snap = await _firestore.collection('users').limit(30).get();
      return snap.docs
          .map((d) => AppUser.fromMap(d.data(), d.id))
          .toList();
    }
    // Firestore prefix search trick: use >= query and <= query\uf8ff
    final snap = await _firestore
        .collection('users')
        .orderBy('displayName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();
    return snap.docs
        .map((d) => AppUser.fromMap(d.data(), d.id))
        .toList();
  }

  /// Live stream of all users (for explore feed)
  Stream<List<AppUser>> getUsersStream() {
    return _firestore
        .collection('users')
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppUser.fromMap(d.data(), d.id)).toList())
        .handleError((e) {
      debugPrint('Error fetching users: $e');
      return <AppUser>[];
    });
  }

  /// Join a trip — adds user to members subcollection, decrements seatsLeft
  Future<bool> joinTrip(String tripId, {String? itineraryId}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final tripRef = _firestore.collection('trips').doc(tripId);
      final memberRef = tripRef.collection('members').doc(user.uid);

      await _firestore.runTransaction((txn) async {
        final tripSnap = await txn.get(tripRef);
        final seatsLeft = (tripSnap.data()?['seatsLeft'] ?? 0) as int;
        if (seatsLeft <= 0) throw Exception('No seats left');

        txn.set(memberRef, {
          'userId': user.uid,
          'joinedAt': FieldValue.serverTimestamp(),
          if (itineraryId != null) 'itineraryId': itineraryId,
        });
        txn.update(tripRef, {'seatsLeft': FieldValue.increment(-1)});
      });
      return true;
    } catch (e) {
      debugPrint('Error joining trip: $e');
      return false;
    }
  }

  /// Create a new trip
  Future<String?> createTrip(Trip trip) async {
    try {
      final ref = await _firestore.collection('trips').add(trip.toMap());
      return ref.id;
    } catch (e) {
      debugPrint('Error creating trip: $e');
      return null;
    }
  }

  /// Submit a custom trip request
  Future<bool> submitCustomTripRequest(Map<String, dynamic> requestData) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await _firestore.collection('custom_trip_requests').add({
        ...requestData,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting custom trip: $e');
      return false;
    }
  }

  /// Get the user's custom planned trips
  Stream<List<Map<String, dynamic>>> getCustomTripRequests(String uid) {
    return _firestore
        .collection('custom_trip_requests')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()..['id'] = d.id).toList())
        .handleError((e) {
      debugPrint('Error getting custom trips: $e');
      return <Map<String, dynamic>>[];
    });
  }

  /// Book an accommodation
  Future<bool> bookStay(Map<String, dynamic> stayData) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await _firestore.collection('booked_stays').add({
        ...stayData,
        'userId': user.uid,
        'bookedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error booking stay: $e');
      return false;
    }
  }

  /// Get the user's booked stays
  Stream<List<Map<String, dynamic>>> getBookedStays(String uid) {
    return _firestore
        .collection('booked_stays')
        .where('userId', isEqualTo: uid)
        .orderBy('bookedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()..['id'] = d.id).toList())
        .handleError((e) {
      debugPrint('Error getting booked stays: $e');
      return <Map<String, dynamic>>[];
    });
  }

  /// Get trips the current user has joined
  Stream<List<String>> getMyJoinedTripIds(String uid) {
    return _firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.reference.parent.parent!.id).toList())
        .handleError((e) {
      debugPrint('Error getting joined trips: $e');
      return <String>[];
    });
  }

  // ─────────────────────────────────────────
  // SOCIAL FEED (POSTS & COMMENTS)
  // ─────────────────────────────────────────

  Stream<List<SocialPost>> getSocialFeed() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SocialPost.fromMap(d.data(), d.id)).toList())
        .handleError((e) {
      debugPrint('Error fetching social feed: $e');
      return <SocialPost>[];
    });
  }

  Stream<List<SocialPost>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SocialPost.fromMap(d.data(), d.id)).toList())
        .handleError((e) {
      debugPrint('Error fetching user posts: $e');
      return <SocialPost>[];
    });
  }

  Future<void> createPost(SocialPost post) async {
    try {
      await _firestore.collection('posts').add(post.toMap());
    } catch (e) {
      debugPrint('Error creating post: $e');
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(postRef);
      if (!snap.exists) return;
      
      final likedBy = List<String>.from(snap.data()?['likedBy'] ?? []);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        txn.update(postRef, {
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(-1)
        });
      } else {
        likedBy.add(userId);
        txn.update(postRef, {
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(1)
        });
      }
    });
  }

  Stream<List<PostComment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostComment.fromMap(d.data(), d.id)).toList())
        .handleError((e) {
      debugPrint('Error fetching comments: $e');
      return <PostComment>[];
    });
  }

  Future<void> addComment(PostComment comment) async {
    try {
      final postRef = _firestore.collection('posts').doc(comment.postId);
      await _firestore.runTransaction((txn) async {
        final newCommentRef = postRef.collection('comments').doc();
        txn.set(newCommentRef, comment.toMap());
        txn.update(postRef, {'commentsCount': FieldValue.increment(1)});
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  // ─────────────────────────────────────────
  // USER REVIEWS
  // ─────────────────────────────────────────

  Stream<List<UserReview>> getUserReviews(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserReview.fromMap(d.data(), d.id)).toList())
        .handleError((e) {
      debugPrint('Error fetching reviews: $e');
      return <UserReview>[];
    });
  }

  Future<void> addReview(UserReview review) async {
    try {
      await _firestore
          .collection('users')
          .doc(review.revieweeId)
          .collection('reviews')
          .add(review.toMap());
    } catch (e) {
      debugPrint('Error adding review: $e');
    }
  }

  // ─────────────────────────────────────────
  // DESTINATIONS (legacy)
  // ─────────────────────────────────────────

  Stream<List<Destination>> getDestinations() {
    return _firestore.collection('destinations').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Destination.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((error) {
      debugPrint('Error fetching destinations: $error');
      return <Destination>[];
    });
  }

  // ─────────────────────────────────────────
  // SEED DATABASE (Developer Tool)
  // ─────────────────────────────────────────
  Future<void> seedDatabase() async {
    try {
      final batch = _firestore.batch();
      
      // Seed Trips
      for (var trip in MockData.trips) {
        final docRef = _firestore.collection('trips').doc();
        batch.set(docRef, trip.toMap());
      }

      // Seed Trending Destinations
      for (var dest in MockData.trendingDestinations) {
        final docRef = _firestore.collection('locations').doc();
        batch.set(docRef, {...dest, 'category': 'trending'});
      }

      // Seed Seasonal Guide
      for (var dest in MockData.seasonalGuide) {
        final docRef = _firestore.collection('locations').doc();
        batch.set(docRef, {...dest, 'category': 'seasonal'});
      }

      // Seed Hidden Gems
      for (var dest in MockData.hiddenGems) {
        final docRef = _firestore.collection('locations').doc();
        batch.set(docRef, {...dest, 'category': 'hidden'});
      }

      // Seed Accommodations
      for (var acc in MockData.accommodations) {
        final docRef = _firestore.collection('accommodations').doc();
        final dataToSave = Map<String, dynamic>.from(acc);
        if (dataToSave.containsKey('color')) {
          // Store color as integer value
          dataToSave['colorInt'] = (dataToSave['color'] as Color).value;
          dataToSave.remove('color');
        }
        batch.set(docRef, dataToSave);
      }

      await batch.commit();
      debugPrint('Database seeded successfully');
    } catch (e) {
      debugPrint('Error seeding database: $e');
    }
  }

  // ─────────────────────────────────────────
  // LIVE EXPLORE DATA
  // ─────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getLocationsByCategory(String category) {
    return _firestore
        .collection('locations')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList())
        .handleError((e) {
      debugPrint('Error fetching locations ($category): $e');
      return <Map<String, dynamic>>[];
    });
  }

  Stream<List<Map<String, dynamic>>> getAccommodations() {
    return _firestore
        .collection('accommodations')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              if (data['colorInt'] != null) {
                data['color'] = Color(data['colorInt'] as int);
              } else {
                data['color'] = const Color(0xFF000000); // fallback
              }
              return data;
            }).toList())
        .handleError((e) {
      debugPrint('Error fetching accommodations: $e');
      return <Map<String, dynamic>>[];
    });
  }
}