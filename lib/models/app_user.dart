class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final String bio;
  final int tripsCount;
  final int followersCount;
  final List<String> badges;
  final int verifiedScore;
  final String gender;
  final String dateOfBirth;
  final String locality;
  final bool isIdentityVerified;
  final bool isOnlyGirlsMode;
  final List<String> following;
  final bool isPrivate;
  final String statusEmoji;
  final bool hasAcceptedTerms;
  final double reputationScore;
  final int totalReviews;
  final String responseTime;
  final List<String> pastTrips;
  final List<String> wishlist;
  final String travelPersonality;
  final bool isBanned;
  final List<String> reportedUsers;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl = '',
    this.bio = '',
    this.tripsCount = 0,
    this.followersCount = 0,
    this.badges = const [],
    this.verifiedScore = 0,
    this.gender = 'unknown',
    this.dateOfBirth = '',
    this.locality = '',
    this.isIdentityVerified = false,
    this.isOnlyGirlsMode = false,
    this.following = const [],
    this.isPrivate = false,
    this.statusEmoji = '',
    this.hasAcceptedTerms = false,
    this.reputationScore = 0.0,
    this.totalReviews = 0,
    this.responseTime = 'Usually responds in an hour',
    this.pastTrips = const [],
    this.wishlist = const [],
    this.travelPersonality = 'The Explorer',
    this.isBanned = false,
    this.reportedUsers = const [],
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      bio: data['bio'] ?? '',
      tripsCount: (data['tripsCount'] ?? 0).toInt(),
      followersCount: (data['followersCount'] ?? 0).toInt(),
      badges: List<String>.from(data['badges'] ?? []),
      verifiedScore: (data['verifiedScore'] ?? 0).toInt(),
      gender: data['gender'] ?? 'unknown',
      dateOfBirth: data['dateOfBirth'] ?? '',
      locality: data['locality'] ?? '',
      isIdentityVerified: data['isIdentityVerified'] ?? false,
      isOnlyGirlsMode: data['isOnlyGirlsMode'] ?? false,
      following: List<String>.from(data['following'] ?? []),
      isPrivate: data['isPrivate'] ?? false,
      statusEmoji: data['statusEmoji'] ?? '',
      hasAcceptedTerms: data['hasAcceptedTerms'] ?? false,
      reputationScore: (data['reputationScore'] ?? 0.0).toDouble(),
      totalReviews: (data['totalReviews'] ?? 0).toInt(),
      responseTime: data['responseTime'] ?? 'Usually responds in an hour',
      pastTrips: List<String>.from(data['pastTrips'] ?? []),
      wishlist: List<String>.from(data['wishlist'] ?? []),
      travelPersonality: data['travelPersonality'] ?? 'The Explorer',
      isBanned: data['isBanned'] ?? false,
      reportedUsers: List<String>.from(data['reportedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'tripsCount': tripsCount,
      'followersCount': followersCount,
      'badges': badges,
      'verifiedScore': verifiedScore,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'locality': locality,
      'isIdentityVerified': isIdentityVerified,
      'isOnlyGirlsMode': isOnlyGirlsMode,
      'following': following,
      'isPrivate': isPrivate,
      'statusEmoji': statusEmoji,
      'hasAcceptedTerms': hasAcceptedTerms,
      'reputationScore': reputationScore,
      'totalReviews': totalReviews,
      'responseTime': responseTime,
      'pastTrips': pastTrips,
      'wishlist': wishlist,
      'travelPersonality': travelPersonality,
      'isBanned': isBanned,
      'reportedUsers': reportedUsers,
    };
  }
}
