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

import 'community_guidelines_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'paywall_screen.dart';

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

    if (targetUid == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<AppUser?>(
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
              baseColor: Theme.of(context).dividerColor,
              highlightColor: Theme.of(context).cardColor,
              child: const CircleAvatar(radius: 50),
            ),
            const SizedBox(height: 20),
            Shimmer.fromColors(
              baseColor: Theme.of(context).dividerColor,
              highlightColor: Theme.of(context).cardColor,
              child: Container(width: 150, height: 20, color: Theme.of(context).cardColor),
            ),
            const SizedBox(height: 10),
            Shimmer.fromColors(
              baseColor: Theme.of(context).dividerColor,
              highlightColor: Theme.of(context).cardColor,
              child: Container(width: 100, height: 15, color: Theme.of(context).cardColor),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) => Shimmer.fromColors(
                baseColor: Theme.of(context).dividerColor,
                highlightColor: Theme.of(context).cardColor,
                child: Container(width: 60, height: 60, color: Theme.of(context).cardColor),
              )),
            ),
            const SizedBox(height: 30),
            Shimmer.fromColors(
              baseColor: Theme.of(context).dividerColor,
              highlightColor: Theme.of(context).cardColor,
              child: Container(width: double.infinity, height: 150, decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 20),
            Shimmer.fromColors(
              baseColor: Theme.of(context).dividerColor,
              highlightColor: Theme.of(context).cardColor,
              child: Container(width: double.infinity, height: 300, color: Theme.of(context).cardColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(AppUser user, {bool isOwnProfile = true}) {
    final isContentVisible = !user.isPrivate || isOwnProfile;
    final photoUrl = user.photoUrl.isNotEmpty && !user.photoUrl.contains('pravatar')
        ? user.photoUrl
        : 'https://api.dicebear.com/9.x/avataaars/png?seed=${user.uid}';

    return CustomScrollView(
      slivers: [
        // ── Collapsing App Bar ──
        SliverAppBar(
          expandedHeight: 280,
          collapsedHeight: 72,
          pinned: true,
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          automaticallyImplyLeading: widget.targetUserId != null,
          iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
          // Collapsed state: avatar on left, action icons on right
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(photoUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName : 'Traveler',
                  style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            if (isOwnProfile)
              IconButton(
                icon: const Icon(Icons.shield_outlined, color: Colors.blue),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityGuidelinesScreen())),
              ),
            if (isOwnProfile)
              IconButton(
                icon: Icon(Icons.settings, color: Theme.of(context).textTheme.bodyLarge?.color),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            if (isOwnProfile)
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: () async {
                  await _firebaseService.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            if (!isOwnProfile)
              IconButton(
                icon: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge?.color),
                onPressed: () => _showReportBottomSheet(user.uid),
              ),
          ],
          // Expanded state: centred avatar + bio
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              color: Theme.of(context).cardColor,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                  child: Column(
                    children: [
                      // ── Avatar + info row ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          GestureDetector(
                            onTap: isOwnProfile ? () => _showAvatarPicker(user) : null,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: (user.isOnlyGirlsMode && user.gender.toLowerCase() == 'female')
                                      ? BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 5)],
                                        )
                                      : null,
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: (user.isOnlyGirlsMode && user.gender.toLowerCase() == 'female')
                                        ? Colors.pinkAccent
                                        : Theme.of(context).dividerColor,
                                    child: CircleAvatar(
                                      radius: 42,
                                      backgroundImage: NetworkImage(photoUrl),
                                      onBackgroundImageError: (e, s) {},
                                    ),
                                  ),
                                ),
                                if (isOwnProfile)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Theme.of(context).cardColor, width: 2),
                                      ),
                                      child: Icon(Icons.camera_alt, size: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right-side info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.displayName.isNotEmpty ? user.displayName : 'Traveler',
                                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (user.isPro)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                                        child: Text('PRO', style: GoogleFonts.outfit(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    if (user.isPro) const SizedBox(width: 6),
                                    if (user.statusEmoji.isNotEmpty)
                                      Text(user.statusEmoji, style: const TextStyle(fontSize: 20))
                                    else
                                      const Icon(Icons.verified, color: Colors.blue, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Trust score
                                Row(
                                  children: [
                                    const Icon(Icons.shield, color: Colors.green, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Trust: ${user.verifiedScore}/100',
                                      style: GoogleFonts.outfit(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Reputation
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Theme.of(context).primaryColor, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${user.reputationScore.toStringAsFixed(1)} Reputation',
                                      style: GoogleFonts.outfit(color: Theme.of(context).primaryColorDark, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Edit Profile / Follow button
                                if (isOwnProfile)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _showEditProfileSheet(user),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.edit, size: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                                                const SizedBox(width: 4),
                                                Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  _buildFollowButton(user),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bio
                      GestureDetector(
                        onTap: isOwnProfile ? () => _editBio(user) : null,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.bio.isNotEmpty ? user.bio : (isOwnProfile ? 'Tap to add your bio...' : 'World Traveler ✈️ | Explorer'),
                                style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOwnProfile) Icon(Icons.edit, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Rest of profile as slivers ──
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildStatsRow(user),
              if (isOwnProfile && !user.isPro) _buildProBanner(),
              _buildBadgesSection(user),
              if (isOwnProfile && user.gender.toLowerCase() == 'female') _buildSettingsToggle(user),
              if (isOwnProfile) _buildDeveloperTools(),
              _buildReviewsSection(user, isOwnProfile),
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
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_outline, size: 40, color: Theme.of(context).textTheme.bodyMedium?.color),
                        const SizedBox(height: 12),
                        Text('Posts are Private',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text('Follow this user to see their posts.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PaywallScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E1E1C), Color(0xFF3A3A35)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upgrade to Pro', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Unlock unlimited AI trips & features', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildBadgesSection(AppUser user) {
    if (user.badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Badges & Achievements', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: user.badges.map((badge) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(badge, style: GoogleFonts.outfit(color: Colors.amber[800], fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
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
                    backgroundColor: isFollowing ? Theme.of(context).dividerColor : Theme.of(context).primaryColor,
                    foregroundColor: isFollowing ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyLarge?.color,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: Text(isFollowing ? 'Unfollow' : 'Follow', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                    label: Text('Chat', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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

  void _showEditProfileSheet(AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit Profile', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
              ),
              title: Text('Change Photo / Avatar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: Text('Update your profile picture', style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showAvatarPicker(user);
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.edit_note, color: Colors.blue),
              ),
              title: Text('Edit Bio', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: Text(user.bio.isNotEmpty ? user.bio : 'Add a bio', style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _editBio(user);
              },
            ),
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
        label: Text('Seed Database (Developer)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
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
                Text('Report User', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800])),
              ],
            ),
            const SizedBox(height: 8),
            Text('Why are you reporting this user? Your report is anonymous.', style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
            const SizedBox(height: 20),
            ...categories.map((category) => ListTile(
              title: Text(category, style: GoogleFonts.outfit()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report submitted for "$category". Thank you for keeping our community safe.', style: GoogleFonts.outfit()),
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



  void _editBio(AppUser user) {
    final bioController = TextEditingController(text: user.bio);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Bio', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
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
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
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
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
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
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
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
                        Icon(Icons.format_quote, color: Theme.of(context).primaryColor, size: 24),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        testimonial['review']!,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontStyle: FontStyle.italic),
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
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4,
                            child: Center(
                              child: Image.network(
                                _galleryImages[index],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          right: 20,
                          child: IconButton(
                            icon: Icon(Icons.close, color: Theme.of(context).cardColor, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Image.network(
                _galleryImages[index],
                fit: BoxFit.cover,
              ),
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
                      Text('Customize Avatar', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _pickAndUploadImage(user);
                        },
                        icon: Icon(Icons.photo_library, color: Theme.of(context).primaryColor, size: 18),
                        label: Text('Upload Image', style: GoogleFonts.outfit(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
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
                            selectedColor: Theme.of(context).primaryColor,
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
                            backgroundColor: Theme.of(context).cardColor,
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
                    icon: Icon(Icons.shuffle, color: Theme.of(context).textTheme.bodyLarge?.color),
                    label: Text('Shuffle', style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
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
        builder: (context) => Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
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
        SnackBar(content: Text('Failed to upload image: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildPostsSection(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Posts', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        StreamBuilder<List<SocialPost>>(
          stream: _firebaseService.getUserPosts(user.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final posts = snapshot.data!;
            if (posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text('No posts yet.', style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color)),
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.content, style: GoogleFonts.outfit(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('${post.likesCount} Likes • ${post.commentsCount} Comments', style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
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
              Text('Reviews', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
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
                                  icon: Icon(index < selectedRating ? Icons.star : Icons.star_border, color: Theme.of(context).primaryColor),
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
                                
                                await _firebaseService.addUserReview(review);
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
                  child: Text('+ Write', style: GoogleFonts.outfit(color: Theme.of(context).primaryColorDark, fontWeight: FontWeight.bold)),
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
                child: Text('No reviews yet.', style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color)),
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
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
                                Text(review.reviewerName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Theme.of(context).primaryColor, size: 12),
                                    Text(review.rating.toString(), style: GoogleFonts.outfit(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(timeago.format(review.createdAt), style: GoogleFonts.outfit(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(review.text, style: GoogleFonts.outfit(fontSize: 14)),
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




