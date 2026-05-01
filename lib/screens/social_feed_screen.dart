import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/social_post.dart';
import '../models/post_comment.dart';
import '../services/firebase_service.dart';
import 'profile_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          StreamBuilder<List<SocialPost>>(
            stream: _firebaseService.getSocialFeed(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.amber)),
                );
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('Be the first to post!',
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('Share your travel moments',
                            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildPostCard(posts[index]).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1),
                    childCount: posts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: const Color(0xFF0A0A1A),
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A3E), Color(0xFF0A0A1A)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Community',
                  style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('Share your adventures ✈️',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag: 'createPost',
      onPressed: () => _showCreatePostSheet(context),
      backgroundColor: Colors.amber,
      icon: const Icon(Icons.add_photo_alternate, color: Colors.black),
      label: Text('New Post', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.04, duration: 900.ms);
  }

  Widget _buildPostCard(SocialPost post) {
    final currentUserId = _firebaseService.currentUser?.uid ?? '';
    final isLiked = post.likedBy.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141428),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(targetUserId: post.authorId),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Colors.amber, Color(0xFFFF6B6B)]),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage((post.authorPhotoUrl.isNotEmpty && !post.authorPhotoUrl.contains('pravatar'))
                        ? post.authorPhotoUrl
                        : 'https://api.dicebear.com/9.x/avataaars/png?seed=${post.authorId}'),
                    onBackgroundImageError: (e, s) {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(timeago.format(post.createdAt),
                          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Traveler', style: GoogleFonts.poppins(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(post.content,
                style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.5)),
          ),
          // Image if exists
          if (post.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                child: Image.network(post.imageUrl, fit: BoxFit.cover, width: double.infinity, height: 220),
              ),
            ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: '${post.likesCount}',
                  color: isLiked ? Colors.red : Colors.white38,
                  onTap: () => _firebaseService.toggleLike(post.id, currentUserId),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentsCount}',
                  color: Colors.white38,
                  onTap: () => _showCommentsSheet(context, post),
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: Colors.white38,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
      ),
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: GoogleFonts.poppins(color: color, fontSize: 13)),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    final TextEditingController contentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141428),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Share a Moment ✨',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: TextField(
                    controller: contentController,
                    maxLines: 4,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "What's on your mind, traveler?",
                      hintStyle: GoogleFonts.poppins(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (contentController.text.trim().isEmpty) return;
                            setState(() => isSubmitting = true);
                            final user = _firebaseService.currentUser;
                            if (user == null) return;
                            final post = SocialPost(
                              id: '',
                              authorId: user.uid,
                              authorName: user.displayName ?? 'Traveler',
                              authorPhotoUrl: user.photoURL ?? '',
                              content: contentController.text.trim(),
                              createdAt: DateTime.now(),
                            );
                            await _firebaseService.createPost(post);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text('Post',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, SocialPost post) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF141428),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Comments', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
            Expanded(
              child: StreamBuilder<List<PostComment>>(
                stream: _firebaseService.getComments(post.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(child: Text('No comments yet. Be the first! 💬', style: GoogleFonts.poppins(color: Colors.white38)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context); // Close bottom sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: comment.authorId)),
                                );
                              },
                              child: CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage((comment.authorPhotoUrl.isNotEmpty && !comment.authorPhotoUrl.contains('pravatar'))
                                    ? comment.authorPhotoUrl
                                    : 'https://api.dicebear.com/9.x/avataaars/png?seed=${comment.authorId}'),
                                onBackgroundImageError: (e, s) {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => ProfileScreen(targetUserId: comment.authorId)),
                                          );
                                        },
                                        child: Text(comment.authorName,
                                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                      const Spacer(),
                                      Text(timeago.format(comment.createdAt),
                                          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(comment.text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12, left: 16, right: 16, top: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A1A),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: TextField(
                        controller: commentController,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      if (commentController.text.trim().isEmpty) return;
                      final user = _firebaseService.currentUser;
                      if (user == null) return;
                      final comment = PostComment(
                        id: '',
                        postId: post.id,
                        authorId: user.uid,
                        authorName: user.displayName ?? 'Traveler',
                        authorPhotoUrl: user.photoURL ?? '',
                        text: commentController.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      commentController.clear();
                      await _firebaseService.addComment(comment);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.amber, Color(0xFFED8F03)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 10)],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
