import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip.dart';
import '../models/app_user.dart';
import '../models/destination.dart';
import '../models/social_post.dart';
import '../models/user_review.dart';
import '../data/mock_data.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../models/ai_trip.dart';
import 'ai_service.dart';

/// Recursively converts a raw [Map<dynamic, dynamic>] (as stored by Hive)
/// into a [Map<String, dynamic>] safe for model deserialization.
Map<String, dynamic> deepCastMap(Map<dynamic, dynamic> raw) {
  return raw.map((key, value) {
    if (value is Map) {
      return MapEntry(key.toString(), deepCastMap(value));
    } else if (value is List) {
      return MapEntry(key.toString(), _deepCastList(value));
    }
    return MapEntry(key.toString(), value);
  });
}

List<dynamic> _deepCastList(List<dynamic> list) {
  return list.map((item) {
    if (item is Map) return deepCastMap(item);
    if (item is List) return _deepCastList(item);
    return item;
  }).toList();
}

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // serverClientId = the Web OAuth client from google-services.json (client_type: 3)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// The UID of the currently signed-in user, or null.
  String? get currentUserUid => _auth.currentUser?.uid;

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
      await _googleSignIn.initialize();

      final account = await _googleSignIn.authenticate();

      final auth = account.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
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
            'gender': 'unknown',
            'dateOfBirth': '',
            'locality': '',
            'isIdentityVerified': false,
            'notifications': {
              'newTrips': true,
              'newFollowers': true,
            },
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

  // ─────────────────────────────────────────
  // TRIPS
  // ─────────────────────────────────────────

  /// Live stream of all trips, optionally filtered (with Hive caching)
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

    final box = Hive.box('trips_cache');

    // 1. Yield from Hive Cache immediately
    if (box.isNotEmpty) {
      try {
        final List<Trip> cachedTrips = [];
        for (var key in box.keys) {
          final data = box.get(key);
          if (data != null && data is Map) {
            // deepCastMap recursively converts _Map<dynamic,dynamic> → Map<String,dynamic>
            cachedTrips.add(Trip.fromMap(deepCastMap(data), key.toString()));
          }
        }
        
        final filteredCache = cachedTrips.where((t) {
          if (t.isOnlyGirls && userGender != 'female') return false;
          if (onlyGirls == true && !t.isOnlyGirls) return false;
          final budgetOk = maxBudget == null || t.budget <= maxBudget;
          final durationOk = maxDuration == null || t.durationDays <= maxDuration;
          return budgetOk && durationOk;
        }).toList();

        if (filteredCache.isNotEmpty) {
          yield filteredCache;
        }
      } catch (e) {
        debugPrint('Hive cache read error: $e');
      }
    }

    Query<Map<String, dynamic>> query =
        _firestore.collection('trips').orderBy('startDate');

    if (onlyGirls == true) {
      query = query.where('isOnlyGirls', isEqualTo: true);
    }

    yield* query.snapshots().map((snap) {
      final trips =
          snap.docs.map((d) => Trip.fromMap(d.data(), d.id)).toList();

      // 2. Update Cache asynchronously
      Future.microtask(() {
        for (var trip in trips) {
          box.put(trip.id, trip.toMap());
        }
      });

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

  Future<void> toggleWishlist(String itemId, {String type = "trip"}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final collectionName = type == "trip" ? "saved_trips" : "saved_places";
    final docRef = _firestore.collection('users').doc(user.uid).collection(collectionName).doc(itemId);

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'savedAt': FieldValue.serverTimestamp(),
          'itemId': itemId,
          'type': type,
        });
      }
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
    }
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

  Future<void> addUserReview(UserReview review) async {
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
          dataToSave['colorInt'] = (dataToSave['color'] as Color).toARGB32();
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

  // ─────────────────────────────────────────
  // WISHLIST / SAVED ITEMS
  // ─────────────────────────────────────────

  // (toggleWishlist is defined above at line 238)

  // ─────────────────────────────────────────
  // COMMUNITY PLACES & REVIEWS
  // ─────────────────────────────────────────

  Future<String?> addPlace(Place place) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = await _firestore.collection('places').add({
      ...place.toMap(),
      'createdBy': user.uid,
    });

    return ref.id;
  }

  Stream<List<Place>> getPlaces() {
    return _firestore
        .collection('places')
        .where('isHidden', isEqualTo: false)
        .orderBy('popularityScore', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Place.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> addReview(String placeId, int rating, String comment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final review = Review(
      userId: user.uid,
      userName: user.displayName ?? "Traveler",
      rating: rating,
      comment: comment,
    );

    // Step 1: Atomic transaction — write review + update rating
    await _firestore.runTransaction((transaction) async {
      final placeRef = _firestore.collection('places').doc(placeId);
      final placeDoc = await transaction.get(placeRef);
      if (!placeDoc.exists) return;

      final data = placeDoc.data()!;
      final currentCount = data['reviewsCount'] ?? 0;
      final currentAvg = (data['avgRating'] ?? 0).toDouble();

      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + rating) / newCount;

      final reviewRef = placeRef.collection('reviews').doc();
      transaction.set(reviewRef, review.toMap());
      transaction.update(placeRef, {
        'reviewsCount': newCount,
        'avgRating': newAvg,
      });
    });
  }


  // ── MODERATION ENGINE ─────────────────────────────────────

  Future<void> reportContent({
    required String contentId,
    required String type, // 'place' or 'review'
    required String reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('reports').add({
      'contentId': contentId,
      'type': type,
      'reason': reason,
      'reportedBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Check thresholds and apply moderation
    await _checkAndApplyModeration(contentId, type);
  }

  Future<void> _checkAndApplyModeration(String contentId, String type) async {
    try {
      final reportSnap = await _firestore
          .collection('reports')
          .where('contentId', isEqualTo: contentId)
          .get();

      final count = reportSnap.docs.length;

      if (type == 'place') {
        final placeRef = _firestore.collection('places').doc(contentId);
        if (count >= 5) {
          // Soft delete: hide and halve score
          final doc = await placeRef.get();
          final currentScore = (doc.data()?['popularityScore'] ?? 0).toDouble();
          await placeRef.update({
            'isHidden': true,
            'popularityScore': currentScore * 0.5,
          });
        } else if (count >= 3) {
          await placeRef.update({'isHidden': true});
        }
      }
    } catch (e) {
      debugPrint('Moderation error: $e');
    }
  }

  Stream<List<Review>> getReviews(String placeId) {
    return _firestore
        .collection('places')
        .doc(placeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Review.fromMap(d.data())).toList());
  }

  Future<int> getUserTrustScore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['verifiedScore'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─────────────────────────────────────────
  // AI TRIPS (ENRICHED)
  // ─────────────────────────────────────────

  Future<String?> saveAITrip(AITrip trip) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = await _firestore.collection('ai_trips').add({
      ...trip.toMap(),
      'userId': user.uid,
    });

    return ref.id;
  }

  Stream<List<AITrip>> getMyAITrips() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('ai_trips')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              return AITrip.fromJson(d.data(), id: d.id);
            }).toList());
  }

  // ─────────────────────────────────────────
  // COLLABORATIVE TRIPS
  // ─────────────────────────────────────────

  /// Add a member by UID to a trip's members array
  Future<void> addMember(String tripId, String userId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  /// Remove a member from a trip
  Future<void> removeMember(String tripId, String userId) async {
    await _firestore.collection('trips').doc(tripId).update({
      'members': FieldValue.arrayRemove([userId]),
    });
  }

  /// Search users by email to invite as collaborators
  Future<Map<String, dynamic>?> searchUserByEmail(String email) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return {'uid': snap.docs.first.id, ...snap.docs.first.data()};
    } catch (e) {
      debugPrint('User search error: $e');
      return null;
    }
  }

  /// Real-time itinerary stream ordered by day
  Stream<List<Map<String, dynamic>>> getItinerary(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('itinerary')
        .orderBy('day')
        .orderBy('updatedAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Add a stop to the shared itinerary
  Future<void> addItineraryItem(
    String tripId,
    Map<String, dynamic> item,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('itinerary')
        .add({
      ...item,
      'addedBy': user.uid,
      'addedByName': user.displayName ?? 'Traveler',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // bump trip's updatedAt so members see a change indicator
    await _firestore.collection('trips').doc(tripId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an itinerary stop — safe partial update with timestamp
  Future<void> updateItineraryItem(
    String tripId,
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('itinerary')
        .doc(itemId)
        .update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an itinerary stop
  Future<void> deleteItineraryItem(String tripId, String itemId) async {
    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('itinerary')
        .doc(itemId)
        .delete();
  }

  /// Get current trip members' profiles
  Future<List<Map<String, dynamic>>> getTripMembers(String tripId) async {
    try {
      final tripDoc =
          await _firestore.collection('trips').doc(tripId).get();
      final members =
          List<String>.from(tripDoc.data()?['members'] ?? []);

      final profiles = await Future.wait(members.map((uid) async {
        final doc = await _firestore.collection('users').doc(uid).get();
        return {'uid': uid, ...?doc.data()};
      }));
      return profiles;
    } catch (e) {
      debugPrint('Get members error: $e');
      return [];
    }
  }

  /// Create a new collaborative trip
  Future<String?> createCollaborativeTrip(String title, DateTime startDate, DateTime endDate) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final ref = await _firestore.collection('trips').add({
        'title': title,
        'organizerId': user.uid,
        'organizerName': user.displayName ?? 'Organizer',
        'organizerAvatar': user.photoURL ?? '',
        'startDate': startDate,
        'endDate': endDate,
        'isCollaborative': true,
        'members': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Add organizer as member in subcollection too if needed
      await ref.collection('members').doc(user.uid).set({
        'userId': user.uid,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      debugPrint('Error creating collaborative trip: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────
  // SOCIAL FEED (AI Trip Sharing)
  // ─────────────────────────────────────────

  List<String> extractHashtags(String text) {
    final regex = RegExp(r"#(\w+)");
    return regex
        .allMatches(text)
        .map((m) => m.group(1)!.toLowerCase())
        .toSet()
        .toList();
  }

  /// Share an AI-generated trip as a public post
  Future<String?> shareAITrip(AITrip trip) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? user.displayName ?? 'Traveler';
    final userAvatar = userDoc.data()?['photoUrl'] ?? '';

    // Extract hashtags from description and title
    final hashtags = extractHashtags('${trip.title} ${trip.description}');

    // Generate semantic embedding
    String placesNames = "";
    if (trip.places.isNotEmpty) {
      placesNames = trip.places.map((p) => p['name']?.toString() ?? '').join(', ');
    }
    final tagString = hashtags.join(' ');
    final embeddingString = "${trip.title} ${trip.description} $placesNames $tagString";
    final embedding = await AIService.getEmbedding(embeddingString);

    final ref = await _firestore.collection('posts').add({
      'userId': user.uid,
      'userName': userName,
      'userAvatar': userAvatar,
      'tripId': trip.id,
      'title': trip.title,
      'description': trip.description,
      'places': trip.places,
      'budget': trip.budget,
      'duration': trip.duration,
      'likesCount': 0,
      'commentsCount': 0,
      'savesCount': 0,
      'trendingScore': 100.0,
      'hashtags': hashtags,
      'embedding': embedding,
      'likedBy': [],
      'visibility': 'public',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Maintain hashtag counts
    for (var tag in hashtags) {
      final tagRef = _firestore.collection('hashtags').doc(tag);
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(tagRef);
        if (snap.exists) {
          txn.update(tagRef, {'count': FieldValue.increment(1)});
        } else {
          txn.set(tagRef, {'count': 1});
        }
      });
    }

    return ref.id;
  }

  /// Real-time public feed stream, ordered by newest, capped at 30
  Stream<List<Map<String, dynamic>>> getFeed() {
    return _firestore
        .collection('posts')
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  // ─────────────────────────────────────────
  // FEED RANKING & PREFERENCES
  // ─────────────────────────────────────────

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  List<double> averageEmbeddings(List<double> currentAvg, List<double> newVector, int newCount) {
    if (currentAvg.isEmpty) return newVector;
    if (newVector.isEmpty || currentAvg.length != newVector.length) return currentAvg;
    
    List<double> avg = List.filled(currentAvg.length, 0);
    // Reverse engineer the sum, add the new vector, divide by new count
    for (int i = 0; i < currentAvg.length; i++) {
      double sum = currentAvg[i] * (newCount - 1);
      avg[i] = (sum + newVector[i]) / newCount;
    }
    return avg;
  }

  /// Update user preferences based on interaction
  Future<void> updateUserPreferences(Map<String, dynamic> post) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final ref = _firestore.collection('users').doc(user.uid);
    
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      
      double avgBudget = 0;
      int avgDuration = 0;
      List<double> semanticProfile = [];
      int interactionsCount = 0;
      
      if (snap.exists) {
        final data = snap.data() ?? {};
        final prefs = data['preferences'] ?? {};
        avgBudget = (prefs['avgBudget'] ?? 0).toDouble();
        avgDuration = (prefs['avgDuration'] ?? 0).toInt();
        if (prefs['semanticProfile'] != null) {
          semanticProfile = List<double>.from(prefs['semanticProfile']);
        }
        interactionsCount = (prefs['interactionsCount'] ?? 0).toInt();
      }
      
      final postBudget = (post['budget'] ?? 0).toDouble();
      final postDuration = (post['duration'] ?? 0).toInt();
      final postEmbedding = post['embedding'] != null 
          ? List<double>.from(post['embedding']) 
          : <double>[];
      
      if (avgBudget == 0) avgBudget = postBudget;
      else avgBudget = (avgBudget + postBudget) / 2;
      
      if (avgDuration == 0) avgDuration = postDuration;
      else avgDuration = ((avgDuration + postDuration) / 2).toInt();
      
      if (postEmbedding.isNotEmpty) {
        interactionsCount++;
        semanticProfile = averageEmbeddings(semanticProfile, postEmbedding, interactionsCount);
      }
      
      txn.set(ref, {
        'lastActiveAt': FieldValue.serverTimestamp(),
        'preferences': {
          'avgBudget': avgBudget,
          'avgDuration': avgDuration,
          'semanticProfile': semanticProfile,
          'interactionsCount': interactionsCount,
        }
      }, SetOptions(merge: true));
    });
  }

  /// Calculate viral trending score
  double calculateTrendingScore(Map<String, dynamic> post) {
    final likes = (post['likesCount'] ?? 0).toInt();
    final comments = (post['commentsCount'] ?? 0).toInt();
    final saves = (post['savesCount'] ?? 0).toInt();

    final createdAt = post['createdAt'];
    double recencyBoost = 1.0;
    if (createdAt is Timestamp) {
      final ageHours = DateTime.now().difference(createdAt.toDate()).inHours;
      recencyBoost = 1 / (1 + ageHours);
    }

    return (likes * 2) + (comments * 3) + (saves * 4) + (recencyBoost * 100);
  }

  /// Calculate personal score for a post
  double calculatePersonalScore({
    required Map<String, dynamic> post,
    required Map<String, dynamic> prefs,
    required List<String> following,
  }) {
    // 1. Semantic Similarity (0.6 weight)
    double semanticSim = 0.0;
    if (prefs['semanticProfile'] != null && post['embedding'] != null) {
      final userEmbedding = List<double>.from(prefs['semanticProfile']);
      final postEmbedding = List<double>.from(post['embedding']);
      semanticSim = cosineSimilarity(userEmbedding, postEmbedding);
      // Ensure positive [0, 1] for scoring
      if (semanticSim < 0) semanticSim = 0;
    }
    
    // Fallback: If no semantic profile yet, use old budget/duration heuristic
    if (semanticSim == 0.0) {
      final prefBudget = (prefs['avgBudget'] ?? 0).toDouble();
      final prefDuration = (prefs['avgDuration'] ?? 0).toInt();
      final postBudget = (post['budget'] ?? 0).toDouble();
      final postDuration = (post['duration'] ?? 0).toInt();
      
      double budgetScore = 0.0;
      if (prefBudget > 0) budgetScore = 1 / (1 + (postBudget - prefBudget).abs() / 5000); 
      double durationScore = 0.0;
      if (prefDuration > 0) durationScore = 1 / (1 + (postDuration - prefDuration).abs());
      
      semanticSim = (budgetScore + durationScore) / 2.0;
    }

    // 2. Trending Score (0.2 weight)
    final trendingScore = (post['trendingScore'] ?? 0.0).toDouble();
    // Normalize: base score without interactions is 100, max useful scale ~1000
    final normalizedTrending = math.min(trendingScore / 1000.0, 1.0);

    // 3. Following Boost (0.2 weight)
    final postUserId = post['userId'] as String?;
    final double followingBoost = (postUserId != null && following.contains(postUserId)) ? 1.0 : 0.0;

    // Final Hybrid Score
    double finalScore = (0.6 * semanticSim) + (0.2 * normalizedTrending) + (0.2 * followingBoost);
    
    // Diversity (random noise to break ties)
    finalScore += math.Random().nextDouble() * 0.05;

    return finalScore;
  }

  /// Fetch ranked personalized feed
  Future<List<Map<String, dynamic>>> getPersonalizedFeed() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final prefsSnap = await _firestore.collection('users').doc(user.uid).get();
    Map<String, dynamic> prefs = {};
    List<String> following = [];
    
    if (prefsSnap.exists) {
      prefs = (prefsSnap.data()?['preferences'] ?? {}) as Map<String, dynamic>;
      following = List<String>.from(prefsSnap.data()?['following'] ?? []);
    }

    final postsSnap = await _firestore
        .collection('posts')
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final posts = postsSnap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      data['score'] = calculatePersonalScore(
        post: data, 
        prefs: prefs, 
        following: following
      );
      return data;
    }).toList();

    posts.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return posts.take(30).toList();
  }

  /// Fetch trending posts by trendingScore
  Future<List<Map<String, dynamic>>> getTrendingPosts() async {
    final snap = await _firestore
        .collection('posts')
        .where('visibility', isEqualTo: 'public')
        .orderBy('trendingScore', descending: true)
        .limit(30)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  /// Search posts by hashtag
  Future<List<Map<String, dynamic>>> getPostsByTag(String tag) async {
    final snap = await _firestore
        .collection('posts')
        .where('visibility', isEqualTo: 'public')
        .where('hashtags', arrayContains: tag.toLowerCase())
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  /// Fetch top trending hashtags
  Future<List<Map<String, dynamic>>> getTrendingHashtags() async {
    final snap = await _firestore
        .collection('hashtags')
        .orderBy('count', descending: true)
        .limit(10)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  // ─────────────────────────────────────────
  // SOCIAL GRAPH (FOLLOWERS)
  // ─────────────────────────────────────────

  Future<void> followUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.runTransaction((txn) async {
      final myRef = _firestore.collection('users').doc(user.uid);
      final targetRef = _firestore.collection('users').doc(targetUserId);

      txn.update(myRef, {
        'following': FieldValue.arrayUnion([targetUserId])
      });

      txn.update(targetRef, {
        'followersCount': FieldValue.increment(1)
      });
      
      txn.set(targetRef.collection('followers').doc(user.uid), {
        'followedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> unfollowUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.runTransaction((txn) async {
      final myRef = _firestore.collection('users').doc(user.uid);
      final targetRef = _firestore.collection('users').doc(targetUserId);

      txn.update(myRef, {
        'following': FieldValue.arrayRemove([targetUserId])
      });

      txn.update(targetRef, {
        'followersCount': FieldValue.increment(-1)
      });

      txn.delete(targetRef.collection('followers').doc(user.uid));
    });
  }

  Future<List<String>> getFollowing() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snap = await _firestore.collection('users').doc(user.uid).get();
    return List<String>.from(snap.data()?['following'] ?? []);
  }

  Stream<bool> isFollowingUser(String targetUserId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snap) {
      final following = List<String>.from(snap.data()?['following'] ?? []);
      return following.contains(targetUserId);
    });
  }

  // ─────────────────────────────────────────
  // USER RECOMMENDATIONS
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSuggestedUsers() async {
    final current = _auth.currentUser;
    if (current == null) return [];

    final meSnap = await _firestore.collection('users').doc(current.uid).get();
    if (!meSnap.exists) return [];

    final me = meSnap.data()!;
    final myFollowing = Set<String>.from(me['following'] ?? []);
    final myTags = Set<String>.from(me['preferences']?['likedTags'] ?? []);
    final myLocality = me['preferences']?['locality'];
    
    List<double> myEmbedding = [];
    if (me['preferences']?['semanticProfile'] != null) {
      myEmbedding = List<double>.from(me['preferences']['semanticProfile']);
    }

    // 1. Candidate Generation
    final active = await _firestore
        .collection('users')
        .orderBy('lastActiveAt', descending: true)
        .limit(30)
        .get();

    final map = <String, Map<String, dynamic>>{};
    
    for (var s in active.docs) {
      map[s.id] = s.data()..['uid'] = s.id;
    }
    
    // Add same locality candidates if we have locality set
    if (myLocality != null && myLocality.isNotEmpty) {
      final nearby = await _firestore
          .collection('users')
          .where('preferences.locality', isEqualTo: myLocality)
          .limit(20)
          .get();
      for (var s in nearby.docs) {
        map[s.id] = s.data()..['uid'] = s.id;
      }
    }

    // Exclude self and already following
    map.remove(current.uid);
    map.removeWhere((k, _) => myFollowing.contains(k));

    final candidates = map.values.toList();

    // Cold Start check
    if (candidates.isEmpty) {
      final snap = await _firestore
          .collection('users')
          .orderBy('followersCount', descending: true)
          .limit(20)
          .get();
      return snap.docs
          .where((d) => d.id != current.uid && !myFollowing.contains(d.id))
          .map((d) => d.data()..['uid'] = d.id)
          .toList();
    }

    // 2. Scoring
    for (var u in candidates) {
      double score = 0;

      // Mutual connections
      final theirFollowing = Set<String>.from(u['following'] ?? []);
      final mutual = myFollowing.intersection(theirFollowing).length;
      score += mutual * 3;

      // Semantic Similarity / Interest Overlap
      if (myEmbedding.isNotEmpty && u['preferences']?['semanticProfile'] != null) {
        final theirEmbedding = List<double>.from(u['preferences']['semanticProfile']);
        final sim = cosineSimilarity(myEmbedding, theirEmbedding);
        if (sim > 0) score += sim * 5; // Heavy boost for meaning match
      } else {
        // Fallback to basic tag matching
        final theirTags = Set<String>.from(u['preferences']?['likedTags'] ?? []);
        final commonTags = myTags.intersection(theirTags).length;
        score += commonTags * 2;
      }

      // Location match
      if (myLocality != null && u['preferences']?['locality'] == myLocality) {
        score += 2;
      }

      // Popularity (log scale)
      final followers = (u['followersCount'] ?? 0).toInt();
      score += math.log(followers + 1);

      // Freshness
      final lastActive = (u['lastActiveAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
      final ageHours = (DateTime.now().millisecondsSinceEpoch - lastActive) / (1000 * 60 * 60);
      score += 1 / (1 + ageHours);

      u['score'] = score;
    }

    // 3. Rank + Diversify
    candidates.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    final result = <Map<String, dynamic>>[];
    final seenLocalities = <String, int>{};

    for (var u in candidates) {
      final loc = u['preferences']?['locality'] ?? 'unknown';
      if ((seenLocalities[loc] ?? 0) >= 3) continue;

      result.add(u);
      seenLocalities[loc] = (seenLocalities[loc] ?? 0) + 1;

      if (result.length >= 15) break; // Limit suggestions
    }

    return result;
  }


  /// Atomic like toggle using transaction
  Future<void> toggleLike(Map<String, dynamic> post) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postId = post['id'] as String;
    final ref = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;

      final postData = snap.data() ?? {};
      final likedBy = List<String>.from(postData['likedBy'] ?? []);
      final bool isLiking = !likedBy.contains(user.uid);
      
      if (isLiking) {
        likedBy.add(user.uid);
      } else {
        likedBy.remove(user.uid);
      }
      
      // Compute new trending score
      postData['likesCount'] = (postData['likesCount'] ?? 0) + (isLiking ? 1 : -1);
      final newScore = calculateTrendingScore(postData);

      txn.update(ref, {
        'likedBy': likedBy,
        'likesCount': FieldValue.increment(isLiking ? 1 : -1),
        'trendingScore': newScore,
      });

      if (isLiking) {
        // Update prefs when liking
        updateUserPreferences(post);
      }
    });
  }

  /// Add a comment + increment commentsCount atomically
  Future<void> addComment(Map<String, dynamic> post, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postId = post['id'] as String;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? user.displayName ?? 'Traveler';
    final userAvatar = userDoc.data()?['photoUrl'] ?? '';

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(postRef);
      if (!snap.exists) return;
      
      final postData = snap.data() ?? {};
      postData['commentsCount'] = (postData['commentsCount'] ?? 0) + 1;
      final newScore = calculateTrendingScore(postData);

      txn.set(postRef.collection('comments').doc(), {
        'userId': user.uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      txn.update(postRef, {
        'commentsCount': FieldValue.increment(1),
        'trendingScore': newScore,
      });
      
      // Update prefs when commenting
      updateUserPreferences(post);
    });
  }

  /// Real-time comments stream for a post
  Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Save a post to the user's saved_posts subcollection
  Future<void> savePost(Map<String, dynamic> post) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postId = post['id'] as String?;
    if (postId == null) return;
    
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(postRef);
      if (!snap.exists) return;

      final postData = snap.data() ?? {};
      postData['savesCount'] = (postData['savesCount'] ?? 0) + 1;
      final newScore = calculateTrendingScore(postData);

      txn.update(postRef, {
        'savesCount': FieldValue.increment(1),
        'trendingScore': newScore,
      });
    });

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_posts')
        .doc(postId)
        .set({...post, 'savedAt': FieldValue.serverTimestamp()});
        
    // Update prefs when saving
    await updateUserPreferences(post);
  }

  /// Check if user already saved a post
  Future<bool> isPostSaved(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_posts')
        .doc(postId)
        .get();
    return doc.exists;
  }

  // ─────────────────────────────────────────
  // LIVE PRESENCE (ephemeral cursors)
  // ─────────────────────────────────────────

  /// Write current user's presence to trip_presence subcollection
  Future<void> updateCursor(String tripId, LatLng? position) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final data = <String, dynamic>{
      'displayName': user.displayName ?? 'Traveler',
      'photoUrl': user.photoURL ?? '',
      'lastActive': FieldValue.serverTimestamp(),
    };
    if (position != null) {
      data['lat'] = position.latitude;
      data['lng'] = position.longitude;
    }
    await _firestore
        .collection('trip_presence')
        .doc(tripId)
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  /// Clear presence when user leaves screen
  Future<void> clearCursor(String tripId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('trip_presence')
        .doc(tripId)
        .collection('users')
        .doc(user.uid)
        .delete();
  }

  /// Real-time stream of who is active in the trip
  /// Filters out stale users (inactive > 60 seconds)
  Stream<List<Map<String, dynamic>>> getPresence(String tripId) {
    return _firestore
        .collection('trip_presence')
        .doc(tripId)
        .collection('users')
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      return snap.docs
          .map((d) {
            final data = d.data();
            data['uid'] = d.id;
            return data;
          })
          .where((u) {
            final ts = u['lastActive'];
            if (ts == null) return false;
            final lastActive = (ts as Timestamp).toDate();
            return now.difference(lastActive).inSeconds < 60;
          })
          .toList();
    });
  }

  // ─────────────────────────────────────────
  // TRIP CHAT
  // ─────────────────────────────────────────

  /// Send a chat message to the trip's chat subcollection
  Future<void> sendMessage(String tripId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? user.displayName ?? 'Traveler';
    final userAvatar = userDoc.data()?['photoUrl'] ?? user.photoURL ?? '';

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('chat')
        .add({
      'userId': user.uid,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time chat stream ordered by time ascending
  Stream<List<Map<String, dynamic>>> getChat(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('chat')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  // ─────────────────────────────────────────
  // ACTIVITY TIMELINE
  // ─────────────────────────────────────────

  /// Log a collaboration action to the activity subcollection
  Future<void> logActivity({
    required String tripId,
    required String action,
    String? itemId,
    String? itemTitle,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? user.displayName ?? 'Traveler';

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('activity')
        .add({
      'userId': user.uid,
      'userName': userName,
      'action': action,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time activity stream ordered newest first
  Stream<List<Map<String, dynamic>>> getActivity(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('activity')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }
}