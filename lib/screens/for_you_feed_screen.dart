import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/social_post.dart';
import '../services/firebase_service.dart';
import '../services/feed_service.dart';
import '../services/rl_service.dart';
import 'profile_screen.dart';

class ForYouFeedScreen extends StatefulWidget {
  const ForYouFeedScreen({super.key});

  @override
  State<ForYouFeedScreen> createState() => _ForYouFeedScreenState();
}

class _ForYouFeedScreenState extends State<ForYouFeedScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FeedService _feedService = FeedService();
  final RLService _rlService = RLService();
  
  List<SocialPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final posts = await _feedService.getForYouFeed(limit: 20);
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        color: Colors.amber,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.amber)),
              )
            else if (_posts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('No posts yet!',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('Follow creators to see their content here.',
                          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPostCard(_posts[index])
                        .animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideY(begin: 0.05),
                    childCount: _posts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
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
              Text('For You',
                  style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('Curated adventures & top creators ✨',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
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
                  onTap: () {
                    _firebaseService.toggleLike({'id': post.id, 'likedBy': [], 'likesCount': post.likesCount});
                    if (!isLiked) {
                      _rlService.logInteraction(post.id, 'like');
                      _rlService.updateUserEmbedding(post.embedding);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentsCount}',
                  color: Colors.white38,
                  onTap: () {
                    _rlService.logInteraction(post.id, 'comment');
                    _rlService.updateUserEmbedding(post.embedding);
                  },
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
}
