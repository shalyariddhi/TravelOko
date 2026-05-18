import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../models/app_user.dart';
import 'profile_screen.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    final uid = firebaseService.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Blocked Users', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: StreamBuilder<AppUser?>(
        stream: firebaseService.getUserProfile(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          final user = snapshot.data;
          final blockedIds = user?.reportedUsers ?? [];

          if (blockedIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 72, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No blocked users', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  const SizedBox(height: 8),
                  Text('People you block won\'t be able to\ninteract with your posts.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Theme.of(context).dividerColor, fontSize: 13)),
                ],
              ),
            );
          }

          return FutureBuilder<List<AppUser?>>(
            future: Future.wait(blockedIds.map((id) async {
              final snap = await firebaseService.getUserProfile(id).first;
              return snap;
            }).toList()),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
              final blockedUsers = snap.data!.whereType<AppUser>().toList();

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: blockedUsers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final blocked = blockedUsers[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(targetUserId: blocked.uid))),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            blocked.photoUrl.isNotEmpty ? blocked.photoUrl : 'https://api.dicebear.com/9.x/avataaars/png?seed=${blocked.uid}',
                          ),
                        ),
                      ),
                      title: Text(blocked.displayName.isNotEmpty ? blocked.displayName : 'Traveler',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      subtitle: Text(blocked.locality.isNotEmpty ? blocked.locality : 'Go-Trivo User',
                          style: GoogleFonts.poppins(color: Theme.of(context).dividerColor, fontSize: 12)),
                      trailing: TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Unblock ${blocked.displayName}?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              content: Text('They will be able to see your posts and interact with you again.',
                                  style: GoogleFonts.poppins()),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                  child: Text('Unblock', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && user != null) {
                            final updated = AppUser(
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
                              reportedUsers: user.reportedUsers.where((id) => id != blocked.uid).toList(),
                              notifications: user.notifications,
                              embedding: user.embedding,
                              feedWeights: user.feedWeights,
                            );
                            await firebaseService.updateUserProfile(updated);
                          }
                        },
                        child: Text('Unblock',
                            style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

