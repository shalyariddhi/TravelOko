import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocked_users_screen.dart';
import 'activity_screen.dart';
import 'saved_maps_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    final userUid = firebaseService.currentUser?.uid;

    if (userUid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: StreamBuilder<AppUser?>(
        stream: firebaseService.getUserProfile(userUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Error loading user data'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Personal Information ──
              Text('Personal Information',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
              const SizedBox(height: 12),
              _buildInfoCard(context, user),

              const SizedBox(height: 28),

              // ── Preferences ──
              Text('Preferences',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
              const SizedBox(height: 12),
              _buildDarkModeToggle(context),
              const SizedBox(height: 12),
              _buildPrivacyToggle(context, user, firebaseService),
              const SizedBox(height: 12),
              _buildNotificationsToggle(context, user, firebaseService),

              const SizedBox(height: 28),

              // ── Identity ──
              Text('Identity',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
              const SizedBox(height: 12),
              _buildNavTile(
                context,
                icon: Icons.emoji_emotions,
                iconColor: Colors.deepPurple,
                title: 'Set Verification Emoji',
                subtitle: 'Your unique identity marker shown on your profile',
                onTap: () => _showEmojiPicker(context, user, firebaseService),
              ),

              const SizedBox(height: 28),

              // ── Activity & Privacy ──
              Text('Activity & Privacy',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
              const SizedBox(height: 12),
              _buildNavTile(
                context,
                icon: Icons.history,
                iconColor: Colors.amber[800]!,
                title: 'Your Activity',
                subtitle: 'See posts you\'ve liked and comments you\'ve made',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen())),
              ),
              const SizedBox(height: 12),
              _buildNavTile(
                context,
                icon: Icons.block,
                iconColor: Colors.red,
                title: 'Blocked Users',
                subtitle: 'Manage people you have blocked',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen())),
              ),

              const SizedBox(height: 28),

              // ── Maps & Offline ──
              Text('Maps & Offline',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
              const SizedBox(height: 12),
              _buildNavTile(
                context,
                icon: Icons.offline_pin,
                iconColor: Colors.green[700]!,
                title: 'Saved Offline Maps',
                subtitle: 'View and manage maps saved for offline use',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedMapsScreen())),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavTile(BuildContext context,
      {required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
          trailing: Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, AppUser user) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Name', user.displayName.isNotEmpty ? user.displayName : 'Not provided'),
          const Divider(height: 1),
          _buildInfoRow(context, 'Email', user.email.isNotEmpty ? user.email : 'Not provided'),
          const Divider(height: 1),
          _buildInfoRow(context, 'Gender', user.gender.isNotEmpty ? user.gender : 'Not provided'),
          const Divider(height: 1),
          _buildInfoRow(context, 'Date of Birth', user.dateOfBirth.isNotEmpty ? user.dateOfBirth : 'Not provided'),
          const Divider(height: 1),
          _buildInfoRow(context, 'Locality', user.locality.isNotEmpty ? user.locality : 'Not provided'),
          const Divider(height: 1),
          _buildInfoRow(context, 'Travel Personality', user.travelPersonality),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(BuildContext context, AppUser user, FirebaseService firebaseService) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SwitchListTile(
        title: Text('Private Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        subtitle: Text('Only followers can see your posts',
            style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
        value: user.isPrivate,
        activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5), activeThumbColor: Theme.of(context).primaryColor,
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
            reputationScore: user.reputationScore,
            totalReviews: user.totalReviews,
            responseTime: user.responseTime,
            pastTrips: user.pastTrips,
            wishlist: user.wishlist,
            travelPersonality: user.travelPersonality,
            isBanned: user.isBanned,
            reportedUsers: user.reportedUsers,
            notifications: user.notifications,
            embedding: user.embedding,
            feedWeights: user.feedWeights,
          );
          await firebaseService.updateUserProfile(updatedUser);
        },
      ),
    );
  }

  Widget _buildNotificationsToggle(BuildContext context, AppUser user, FirebaseService firebaseService) {
    final newTripsEnabled = user.notifications['newTrips'] ?? true;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SwitchListTile(
        title: Text('Push Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        subtitle: Text('Get notified when people you follow post a new trip',
            style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
        value: newTripsEnabled,
        activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5), activeThumbColor: Theme.of(context).primaryColor,
        onChanged: (bool value) async {
          final updatedNotifications = Map<String, bool>.from(user.notifications);
          updatedNotifications['newTrips'] = value;

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
            notifications: updatedNotifications,
            embedding: user.embedding,
            feedWeights: user.feedWeights,
          );
          await firebaseService.updateUserProfile(updatedUser);
        },
      ),
    );
  }

  void _showEmojiPicker(BuildContext context, AppUser user, FirebaseService firebaseService) {
    final List<String> emojis = ['👑', '✈️', '🌍', '🔥', '💎', '🌟', '🚀', '🌴', '🌻', '🎒'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Verification Emoji',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('This emoji appears on your profile next to your name.',
                style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: emojis.map((emoji) {
                final isSelected = user.statusEmoji == emoji;
                return GestureDetector(
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
                      reputationScore: user.reputationScore,
                      totalReviews: user.totalReviews,
                      responseTime: user.responseTime,
                      pastTrips: user.pastTrips,
                      wishlist: user.wishlist,
                      travelPersonality: user.travelPersonality,
                      isBanned: user.isBanned,
                      reportedUsers: user.reportedUsers,
                      notifications: user.notifications,
                      embedding: user.embedding,
                      feedWeights: user.feedWeights,
                    );
                    await firebaseService.updateUserProfile(updatedUser);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber.withValues(alpha: 0.2) : Theme.of(context).dividerColor,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.amber, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (user.statusEmoji.isNotEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final updatedUser = AppUser(
                    uid: user.uid, displayName: user.displayName, email: user.email,
                    photoUrl: user.photoUrl, bio: user.bio, tripsCount: user.tripsCount,
                    followersCount: user.followersCount, badges: user.badges,
                    verifiedScore: user.verifiedScore, gender: user.gender,
                    dateOfBirth: user.dateOfBirth, locality: user.locality,
                    isIdentityVerified: user.isIdentityVerified, isOnlyGirlsMode: user.isOnlyGirlsMode,
                    following: user.following, isPrivate: user.isPrivate,
                    statusEmoji: '', hasAcceptedTerms: user.hasAcceptedTerms,
                    reputationScore: user.reputationScore, totalReviews: user.totalReviews,
                    responseTime: user.responseTime, pastTrips: user.pastTrips,
                    wishlist: user.wishlist, travelPersonality: user.travelPersonality,
                    isBanned: user.isBanned, reportedUsers: user.reportedUsers,
                    notifications: user.notifications, embedding: user.embedding,
                    feedWeights: user.feedWeights,
                  );
                  await firebaseService.updateUserProfile(updatedUser);
                },
                child: Text('Remove Emoji', style: GoogleFonts.outfit(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildDarkModeToggle(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        final isDarkMode = currentMode == ThemeMode.dark;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: SwitchListTile(
            title: Text('Dark Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
            subtitle: Text('Switch to a cinematic dark theme',
                style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
            value: isDarkMode,
            activeTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.5), activeThumbColor: Theme.of(context).primaryColor,
            onChanged: (bool value) async {
              themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDarkMode', value);
            },
          ),
        );
      },
    );
  }
}

