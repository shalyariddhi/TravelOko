import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../models/app_user.dart';
import '../models/social_post.dart';
import '../models/user_review.dart';
import 'login_screen.dart';
import 'quiz_screen.dart';
import 'community_guidelines_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? targetUserId;
  const ProfileScreen({super.key, this.targetUserId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  final List<String> _galleryImages = [
    'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1504150558240-0b4fd8946624?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?auto=format&fit=crop&w=400&q=80',
  ];

  final List<Map<String, String>> _testimonials = [
    {
      'name': 'Sarah Jenkins',
      'review': 'Best travel buddy! We explored Santorini together and she knew all the hidden spots.',
      'image': 'https://api.dicebear.com/9.x/avataaars/png?seed=5',
    },
    {
      'name': 'Emma Wood',
      'review': 'Super reliable and fun. The Bali trip was unforgettable thanks to her planning.',
      'image': 'https://api.dicebear.com/9.x/avataaars/png?seed=9',
    },
    {
      'name': 'Jessica T.',
      'review': 'A very trustworthy companion. Highly recommend traveling with her!',
      'image': 'https://api.dicebear.com/9.x/avataaars/png?seed=20',
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentFirebaseUser = _firebaseService.currentUser;
    final isOwnProfile = widget.targetUserId == null || widget.targetUserId == currentFirebaseUser?.uid;
    final targetUid = isOwnProfile ? currentFirebaseUser?.uid : widget.targetUserId;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isOwnProfile ? 'Profile' : 'Traveler Profile',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.shield_outlined, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommunityGuidelinesScreen()),
                );
              },
            ),
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await _firebaseService.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          if (!isOwnProfile)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () => _showReportBottomSheet(targetUid!),
            ),
        ],
      ),
      body: targetUid == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<AppUser?>(
              stream: _firebaseService.getUserProfile(targetUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }
                
                final appUser = snapshot.data;
                if (appUser == null) {
                  return const Center(child: Text('Error loading profile'));
                }
                
                return _buildProfileContent(appUser, isOwnProfile: isOwnProfile);
              },
            ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: const CircleAvatar(radius: 50),
            ),
            const SizedBox(height: 20),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: 150, height: 20, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: 100, height: 15, color: Colors.white),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(width: 60, height: 60, color: Colors.white),
              )),
            ),
            const SizedBox(height: 30),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 20),
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: double.infinity, height: 300, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(AppUser user, {bool isOwnProfile = true}) {
    final isContentVisible = !user.isPrivate || isOwnProfile;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(user, isOwnProfile),
          if (!isOwnProfile) _buildFollowButton(user),
          _buildStatsRow(user),
          if (isOwnProfile && user.gender.toLowerCase() == 'female') _buildSettingsToggle(user),
          if (isOwnProfile) _buildPrivacyToggle(user),
          if (isOwnProfile) _buildSetEmojiButton(user),
          if (isOwnProfile) _buildDeveloperTools(),

          // ── Reviews are ALWAYS visible (safety feature) ──
          _buildReviewsSection(user, isOwnProfile),

          // ── Posts & Gallery are hidden when private & not following ──
          if (isContentVisible) ...[ 
            _buildPostsSection(user),
            _buildTestimonialsSection(),
            _buildGallerySection(),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Posts are Private',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Follow this user to see their posts.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildFollowButton(AppUser user) {
    return StreamBuilder<AppUser?>(
      stream: _firebaseService.getUserProfile(_firebaseService.currentUser!.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final currentUser = snapshot.data!;
        final isFollowing = currentUser.following.contains(user.uid);
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (isFollowing) {
                      await _firebaseService.unfollowUser(user.uid);
                    } else {
                      await _firebaseService.followUser(user.uid);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey[300] : Colors.amber,
                    foregroundColor: isFollowing ? Colors.black87 : Colors.black87,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: Text(isFollowing ? 'Unfollow' : 'Follow', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
              if (isFollowing) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUser: user)));
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text('Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[900],
                      minimumSize: const Size(double.infinity, 45),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildPrivacyToggle(AppUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: SwitchListTile(
          title: Text('Private Account', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          subtitle: Text('Only followers can see your posts', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          value: user.isPrivate,
          activeColor: Colors.amber,
          onChanged: (bool value) async {
            final updatedUser = AppUser(
              uid: user.uid,
              displayName: user.displayName,
              email: user.email,
              photoUrl: user.photoUrl,
              bio: user.bio,
              tripsCount: user.tripsCount,
              followersCount: user.followersCount,
              badges: user.badges,
              verifiedScore: user.verifiedScore,
              gender: user.gender,
              dateOfBirth: user.dateOfBirth,
              locality: user.locality,
              isIdentityVerified: user.isIdentityVerified,
              isOnlyGirlsMode: user.isOnlyGirlsMode,
              following: user.following,
              isPrivate: value,
              statusEmoji: user.statusEmoji,
              hasAcceptedTerms: user.hasAcceptedTerms,
            );
            await _firebaseService.updateUserProfile(updatedUser);
          },
        ),
      ),
    );
  }

  Widget _buildSetEmojiButton(AppUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.emoji_emotions),
        label: Text('Set Verification Emoji', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[100],
          foregroundColor: Colors.blue[900],
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () {
          _showEmojiPicker(user);
        },
      ),
    );
  }

  void _showEmojiPicker(AppUser user) {
    final List<String> emojis = ['👑', '✈️', '🌍', '🔥', '💎', '🌟', '🚀', '🌴', '🌻', '🎒'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Verification Emoji', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: emojis.map((emoji) => GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  final updatedUser = AppUser(
                    uid: user.uid,
                    displayName: user.displayName,
                    email: user.email,
                    photoUrl: user.photoUrl,
                    bio: user.bio,
                    tripsCount: user.tripsCount,
                    followersCount: user.followersCount,
                    badges: user.badges,
                    verifiedScore: user.verifiedScore,
                    gender: user.gender,
                    dateOfBirth: user.dateOfBirth,
                    locality: user.locality,
                    isIdentityVerified: user.isIdentityVerified,
                    isOnlyGirlsMode: user.isOnlyGirlsMode,
                    following: user.following,
                    isPrivate: user.isPrivate,
                    statusEmoji: emoji,
                    hasAcceptedTerms: user.hasAcceptedTerms,
                  );
                  await _firebaseService.updateUserProfile(updatedUser);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeveloperTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.cloud_upload),
        label: Text('Seed Database (Developer)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seeding Database...')),
          );
          await _firebaseService.seedDatabase();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database Seeded Successfully!'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  void _showReportBottomSheet(String targetUserId) {
    final categories = ['Spam', 'Harassment', 'Fake Profile', 'Inappropriate Content', 'Other'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.report_problem, color: Colors.red),
                const SizedBox(width: 8),
                Text('Report User', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800])),
              ],
            ),
            const SizedBox(height: 8),
            Text('Why are you reporting this user? Your report is anonymous.', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 20),
            ...categories.map((category) => ListTile(
              title: Text(category, style: GoogleFonts.poppins()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report submitted for "$category". Thank you for keeping our community safe.', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.green,
                  ),
                );
                // Real implementation would save report to Firestore here
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppUser user, bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: isOwnProfile ? () => _showAvatarPicker(user) : null,
            child: Stack(
              children: [
                Container(
                  decoration: (user.isOnlyGirlsMode && user.gender.toLowerCase() == 'female') ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ) : null,
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: (user.isOnlyGirlsMode && user.gender.toLowerCase() == 'female') ? Colors.pinkAccent : Colors.transparent,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage((user.photoUrl.isNotEmpty && !user.photoUrl.contains('pravatar')) ? user.photoUrl : 'https://api.dicebear.com/9.x/avataaars/png?seed=${user.uid}'),
                      onBackgroundImageError: (e, s) {},
                    ),
                  ),
                ),
                if (isOwnProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit, size: 16, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          if (user.statusEmoji.isNotEmpty)
            Column(
              children: [
                Text(user.statusEmoji, style: const TextStyle(fontSize: 36)),
                Text('Verified', style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
              ],
            ).animate().scale(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.displayName.isNotEmpty ? user.displayName : 'Traveler',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (user.statusEmoji.isEmpty) ...[
                const SizedBox(width: 5),
                const Icon(Icons.verified, color: Colors.blue, size: 24),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Personality Badge
          GestureDetector(
            onTap: isOwnProfile ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelPersonalityQuizScreen())) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology, color: Colors.purple, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    user.travelPersonality,
                    style: GoogleFonts.poppins(
                      color: Colors.purple[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (isOwnProfile) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.edit, color: Colors.purple[300], size: 14),
                  ]
                ],
              ),
            ),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Trust Score: ${user.verifiedScore}/100',
                  style: GoogleFonts.poppins(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isOwnProfile ? () => _editBio(user) : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    user.bio.isNotEmpty ? user.bio : (isOwnProfile ? 'Tap to add your bio...' : 'World Traveler ✈️ | Explorer'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 14),
                  ),
                ),
                if (isOwnProfile) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.edit, size: 14, color: Colors.grey[400]),
                ]
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '${user.reputationScore.toStringAsFixed(1)} Reputation',
                style: GoogleFonts.poppins(color: Colors.amber[800], fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              Text(
                user.responseTime,
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editBio(AppUser user) {
    final bioController = TextEditingController(text: user.bio);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Bio', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: bioController,
            maxLength: 150,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share a little about yourself...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newBio = bioController.text.trim();
                Navigator.pop(context);
                final updatedUser = AppUser(
                  uid: user.uid,
                  displayName: user.displayName,
                  email: user.email,
                  photoUrl: user.photoUrl,
                  bio: newBio,
                  tripsCount: user.tripsCount,
                  followersCount: user.followersCount,
                  badges: user.badges,
                  verifiedScore: user.verifiedScore,
                  gender: user.gender,
                  dateOfBirth: user.dateOfBirth,
                  locality: user.locality,
                  isIdentityVerified: user.isIdentityVerified,
                  isOnlyGirlsMode: user.isOnlyGirlsMode,
                  following: user.following,
                  isPrivate: user.isPrivate,
                  statusEmoji: user.statusEmoji,
                  hasAcceptedTerms: user.hasAcceptedTerms,
                  reputationScore: user.reputationScore,
                  totalReviews: user.totalReviews,
                  responseTime: user.responseTime,
                  pastTrips: user.pastTrips,
                  wishlist: user.wishlist,
                  travelPersonality: user.travelPersonality,
                  isBanned: user.isBanned,
                  reportedUsers: user.reportedUsers,
                );
                await _firebaseService.updateUserProfile(updatedUser);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(AppUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Trips', user.tripsCount.toString()),
          _buildStatItem('Followers', user.followersCount.toString()),
          _buildStatItem('Following', user.following.length.toString()),
          _buildStatItem('Reviews', user.totalReviews.toString()),
        ],
      ),
    );
  }


  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSettingsToggle(AppUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.pink[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.pink.withValues(alpha: 0.3)),
        ),
        child: SwitchListTile(
          title: const Text(
            'Girliees Mode',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
          ),
          subtitle: const Text(
            'Travel exclusively with female companions',
            style: TextStyle(fontSize: 12),
          ),
          value: user.isOnlyGirlsMode,
          activeTrackColor: Colors.pinkAccent.withValues(alpha: 0.5),
          activeThumbColor: Colors.pinkAccent,
          onChanged: (bool value) async {
            final updatedUser = AppUser(
              uid: user.uid,
              displayName: user.displayName,
              email: user.email,
              photoUrl: user.photoUrl,
              bio: user.bio,
              tripsCount: user.tripsCount,
              followersCount: user.followersCount,
              badges: user.badges,
              verifiedScore: user.verifiedScore,
              gender: user.gender,
              dateOfBirth: user.dateOfBirth,
              locality: user.locality,
              isIdentityVerified: user.isIdentityVerified,
              isOnlyGirlsMode: value,
            );
            await _firebaseService.updateUserProfile(updatedUser);
          },
          secondary: const Icon(Icons.female, color: Colors.pinkAccent),
        ),
      ),
    );
  }

  Widget _buildTestimonialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
          child: Text(
            'Traveler Testimonials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: _testimonials.length,
            itemBuilder: (context, index) {
              final testimonial = _testimonials[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(testimonial['image']!),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          testimonial['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        const Icon(Icons.format_quote, color: Colors.amber, size: 24),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        testimonial['review']!,
                        style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                        overflow: TextOverflow.fade,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 15),
          child: Text(
            'Past Trips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: _galleryImages.length,
          itemBuilder: (context, index) {
            return Image.network(
              _galleryImages[index],
              fit: BoxFit.cover,
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  void _showAvatarPicker(AppUser user) {
    final styles = ['avataaars', 'micah', 'adventurer', 'fun-emoji', 'bottts', 'lorelei'];
    String selectedStyle = 'avataaars';
    int seedOffset = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Customize Avatar', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _pickAndUploadImage(user);
                        },
                        icon: const Icon(Icons.photo_library, color: Colors.amber, size: 18),
                        label: Text('Upload Image', style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Style Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: styles.map((style) {
                        final isSelected = selectedStyle == style;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(style),
                            selected: isSelected,
                            selectedColor: Colors.amber,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => selectedStyle = style);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Avatar Grid
                  SizedBox(
                    height: 280,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        final seed = '${user.uid}_${seedOffset + index}';
                        final url = 'https://api.dicebear.com/9.x/$selectedStyle/png?seed=$seed';
                        
                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(ctx);
                            final updated = AppUser(
                              uid: user.uid,
                              displayName: user.displayName,
                              email: user.email,
                              photoUrl: url,
                              bio: user.bio,
                              tripsCount: user.tripsCount,
                              followersCount: user.followersCount,
                              badges: user.badges,
                              verifiedScore: user.verifiedScore,
                              gender: user.gender,
                              dateOfBirth: user.dateOfBirth,
                              locality: user.locality,
                              isIdentityVerified: user.isIdentityVerified,
                              isOnlyGirlsMode: user.isOnlyGirlsMode,
                              following: user.following,
                              isPrivate: user.isPrivate,
                              statusEmoji: user.statusEmoji,
                              hasAcceptedTerms: user.hasAcceptedTerms,
                            );
                            await _firebaseService.updateUserProfile(updated);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.grey[100],
                            backgroundImage: NetworkImage(url),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Shuffle Button
                  ElevatedButton.icon(
                    onPressed: () {
                      setModalState(() {
                        seedOffset += 9;
                      });
                    },
                    icon: const Icon(Icons.shuffle, color: Colors.black87),
                    label: Text('Shuffle', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(AppUser user) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (pickedFile == null) return;

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.amber)),
      );

      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance.ref().child('avatars').child('${user.uid}.jpg');
      
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      final updated = AppUser(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: downloadUrl,
        bio: user.bio,
        tripsCount: user.tripsCount,
        followersCount: user.followersCount,
        badges: user.badges,
        verifiedScore: user.verifiedScore,
        gender: user.gender,
        dateOfBirth: user.dateOfBirth,
        locality: user.locality,
        isIdentityVerified: user.isIdentityVerified,
        isOnlyGirlsMode: user.isOnlyGirlsMode,
        following: user.following,
        isPrivate: user.isPrivate,
        statusEmoji: user.statusEmoji,
        hasAcceptedTerms: user.hasAcceptedTerms,
      );

      await _firebaseService.updateUserProfile(updated);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildPostsSection(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Posts', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<List<SocialPost>>(
          stream: _firebaseService.getUserPosts(user.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final posts = snapshot.data!;
            if (posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('No posts yet.', style: GoogleFonts.poppins(color: Colors.grey)),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.content, style: GoogleFonts.poppins(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('${post.likesCount} Likes • ${post.commentsCount} Comments', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewsSection(AppUser user, bool isOwnProfile) {
    final reviewController = TextEditingController();
    double selectedRating = 5.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reviews', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              if (!isOwnProfile)
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          title: const Text('Write a Review'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) => IconButton(
                                  icon: Icon(index < selectedRating ? Icons.star : Icons.star_border, color: Colors.amber),
                                  onPressed: () => setState(() => selectedRating = index + 1.0),
                                )),
                              ),
                              TextField(
                                controller: reviewController,
                                maxLines: 3,
                                decoration: const InputDecoration(hintText: 'Share your experience...'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () async {
                                final currentUser = _firebaseService.currentUser;
                                if (currentUser == null) return;
                                if (reviewController.text.trim().isEmpty) return;
                                
                                final review = UserReview(
                                  id: '',
                                  reviewerId: currentUser.uid,
                                  reviewerName: currentUser.displayName ?? 'Traveler',
                                  reviewerPhotoUrl: currentUser.photoURL ?? '',
                                  revieweeId: user.uid,
                                  rating: selectedRating,
                                  text: reviewController.text.trim(),
                                  createdAt: DateTime.now(),
                                );
                                
                                await _firebaseService.addReview(review);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                              child: const Text('Submit'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Text('+ Write', style: GoogleFonts.poppins(color: Colors.amber[800], fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        StreamBuilder<List<UserReview>>(
          stream: _firebaseService.getUserReviews(user.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final reviews = snapshot.data!;
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('No reviews yet.', style: GoogleFonts.poppins(color: Colors.grey)),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16, 
                            backgroundImage: NetworkImage((review.reviewerPhotoUrl.isNotEmpty && !review.reviewerPhotoUrl.contains('pravatar')) ? review.reviewerPhotoUrl : 'https://api.dicebear.com/9.x/avataaars/png?seed=${review.reviewerId}'),
                            onBackgroundImageError: (e, s) {},
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(review.reviewerName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 12),
                                    Text(review.rating.toString(), style: GoogleFonts.poppins(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(timeago.format(review.createdAt), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(review.text, style: GoogleFonts.poppins(fontSize: 14)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
