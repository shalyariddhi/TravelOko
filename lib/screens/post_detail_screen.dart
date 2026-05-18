import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/social_post.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';
import 'profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final SocialPost post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    // Track unique view when the post detail screen is opened
    _analyticsService.incrementUniqueView(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _firebaseService.currentUser?.uid ?? '';
    final isLiked = widget.post.likedBy.contains(currentUserId);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Post', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(targetUserId: widget.post.authorId),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage((widget.post.authorPhotoUrl.isNotEmpty && !widget.post.authorPhotoUrl.contains('pravatar'))
                          ? widget.post.authorPhotoUrl
                          : 'https://api.dicebear.com/9.x/avataaars/png?seed=${widget.post.authorId}'),
                      onBackgroundImageError: (e, s) {},
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.post.authorName,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(timeago.format(widget.post.createdAt),
                            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Post content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(widget.post.content,
                  style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, height: 1.5)),
            ),
            
            const SizedBox(height: 16),
            
            // Image if exists
            if (widget.post.imageUrl.isNotEmpty)
              Image.network(widget.post.imageUrl, fit: BoxFit.cover, width: double.infinity),
              
            const SizedBox(height: 16),
            
            // Engagement Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: '${widget.post.likesCount}',
                    color: isLiked ? Colors.red : Colors.white38,
                    onTap: () => _firebaseService.toggleLike({'id': widget.post.id, 'likedBy': [], 'likesCount': widget.post.likesCount}),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${widget.post.commentsCount}',
                    color: Colors.white38,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(color: color, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
