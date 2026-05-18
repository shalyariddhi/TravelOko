import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import '../models/social_post.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();
    final uid = firebaseService.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Your Activity', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
          bottom: TabBar(
            labelColor: Colors.amber[800],
            unselectedLabelColor: Theme.of(context).dividerColor,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(child: Text('Liked Posts', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
              Tab(child: Text('My Comments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LikedPostsTab(uid: uid, firebaseService: firebaseService),
            _MyCommentsTab(uid: uid, firebaseService: firebaseService),
          ],
        ),
      ),
    );
  }
}

class _LikedPostsTab extends StatelessWidget {
  final String uid;
  final FirebaseService firebaseService;
  const _LikedPostsTab({required this.uid, required this.firebaseService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('likedBy', arrayContains: uid)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 72, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No liked posts yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                const SizedBox(height: 8),
                Text('Posts you like will appear here.',
                    style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          );
        }
        final posts = snapshot.data!.docs
            .map((doc) => SocialPost.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final post = posts[index];
            return _PostCard(post: post, indicator: Icons.favorite, indicatorColor: Colors.red)
                .animate()
                .fadeIn(duration: 400.ms, delay: (index * 50).ms);
          },
        );
      },
    );
  }
}

class _MyCommentsTab extends StatelessWidget {
  final String uid;
  final FirebaseService firebaseService;
  const _MyCommentsTab({required this.uid, required this.firebaseService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('comments')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 72, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No comments yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                const SizedBox(height: 8),
                Text('Your comments on posts will appear here.',
                    style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text('You commented', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      Text(timeago.format(createdAt), style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      data['text'] ?? '',
                      style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms);
          },
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final SocialPost post;
  final IconData indicator;
  final Color indicatorColor;
  const _PostCard({required this.post, required this.indicator, required this.indicatorColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                post.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(
                        post.authorPhotoUrl.isNotEmpty
                            ? post.authorPhotoUrl
                            : 'https://api.dicebear.com/9.x/avataaars/png?seed=${post.authorId}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(post.authorName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    Icon(indicator, color: indicatorColor, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                const SizedBox(height: 6),
                Text(timeago.format(post.createdAt),
                    style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
