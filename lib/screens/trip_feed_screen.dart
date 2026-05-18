import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class TripFeedScreen extends StatefulWidget {
  const TripFeedScreen({super.key});

  @override
  State<TripFeedScreen> createState() => _TripFeedScreenState();
}

class _TripFeedScreenState extends State<TripFeedScreen> {
  final _firebaseService = FirebaseService();
  final String? _myUid = FirebaseService().currentUserUid;

  Future<List<Map<String, dynamic>>>? _feedFuture;
  String _feedType = 'for_you'; // 'for_you', 'trending', 'tag'
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  void _loadFeed() {
    setState(() {
      if (_feedType == 'for_you') {
        _feedFuture = _firebaseService.getPersonalizedFeed();
      } else if (_feedType == 'trending') {
        _feedFuture = _firebaseService.getTrendingPosts();
      } else if (_feedType == 'tag' && _selectedTag != null) {
        _feedFuture = _firebaseService.getPostsByTag(_selectedTag!);
      }
    });
  }

  Widget _buildTab(String title, String type) {
    final isSelected = _feedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _feedType = type;
          _selectedTag = null;
          _loadFeed();
        });
      },
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade500)),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(2)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text('Explore',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                      color: Colors.deepPurple, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('Live', style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.deepPurple,
                  fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── TABS ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _buildTab('For You', 'for_you'),
                const SizedBox(width: 20),
                _buildTab('Trending', 'trending'),
              ],
            ),
          ),
          
          // ── HASHTAGS ──────────────────────────────────────
          _TrendingHashtagsWidget(
            firebaseService: _firebaseService,
            selectedTag: _selectedTag,
            onTagSelected: (tag) {
              setState(() {
                if (_selectedTag == tag && _feedType == 'tag') {
                  _selectedTag = null;
                  _feedType = 'trending';
                } else {
                  _selectedTag = tag;
                  _feedType = 'tag';
                }
                _loadFeed();
              });
            },
          ),
          
          // ── SUGGESTED USERS ───────────────────────────────
          if (_feedType == 'for_you')
            _SuggestedUsersCarousel(firebaseService: _firebaseService),
          
          // ── FEED ──────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadFeed();
                await _feedFuture;
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _feedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading feed: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyFeed();
                  }

                  final posts = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: posts.length,
                    itemBuilder: (context, index) =>
                        _PostCard(
                          post: posts[index],
                          myUid: _myUid,
                          firebaseService: _firebaseService,
                        ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text('No trips shared yet',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('Generate an AI trip and share it with the world!',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ── POST CARD ────────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String? myUid;
  final FirebaseService firebaseService;

  const _PostCard({
    required this.post,
    required this.myUid,
    required this.firebaseService,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  late int _likeCount;
  bool _saved = false;
  bool _isLiking = false;

  late AnimationController _heartController;
  late Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    final likedBy = List<String>.from(widget.post['likedBy'] ?? []);
    _liked = widget.myUid != null && likedBy.contains(widget.myUid);
    _likeCount = widget.post['likesCount'] ?? 0;

    _heartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _heartAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
        CurvedAnimation(parent: _heartController, curve: Curves.elasticOut));

    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final s = await widget.firebaseService.isPostSaved(widget.post['id']);
    if (mounted) setState(() => _saved = s);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;
    setState(() {
      _isLiking = true;
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    _heartController.forward().then((_) => _heartController.reverse());
    try {
      await widget.firebaseService.toggleLike(widget.post);
    } catch (_) {
      setState(() {
        _liked = !_liked;
        _likeCount += _liked ? 1 : -1;
      });
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _savePost() async {
    await widget.firebaseService.savePost(widget.post);
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to your collection!',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        post: widget.post,
        firebaseService: widget.firebaseService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = (widget.post['places'] as List?)?.cast<Map>() ?? [];
    final post = widget.post;
    final avatar = post['userAvatar'] as String? ?? '';
    final userName = post['userName'] as String? ?? 'Traveler';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.deepPurple.shade100,
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Text(userName[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(userName,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      _FollowButton(
                        targetUserId: post['userId'] as String? ?? '',
                        myUid: widget.myUid,
                        firebaseService: widget.firebaseService,
                      ),
                    ]),
                    Text(
                      '${post['duration'] ?? 0} days • ₹${post['budget'] ?? 0}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('AI Trip',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          // ── TITLE + DESCRIPTION ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post['title'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  post['description'] ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── PLACE CHIPS ──────────────────────────────────
          if (places.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: places.take(5).map((p) {
                  final name = p['name'] ?? p.toString();
                  final hasCoords = p['lat'] != null;
                  return Chip(
                    avatar: Icon(
                      hasCoords ? Icons.location_on : Icons.location_off,
                      size: 14,
                      color: hasCoords ? Colors.deepPurple : Colors.grey,
                    ),
                    label: Text(name,
                        style: GoogleFonts.poppins(fontSize: 11)),
                    backgroundColor: Colors.deepPurple.shade50,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ),

          // ── DIVIDER ──────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Divider(height: 1),
          ),

          // ── ACTION BAR ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Row(children: [
              // Like
              GestureDetector(
                onTap: _toggleLike,
                child: Row(children: [
                  ScaleTransition(
                    scale: _heartAnim,
                    child: Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? Colors.red : Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('$_likeCount',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _liked ? Colors.red : Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(width: 20),

              // Comment
              GestureDetector(
                onTap: _openComments,
                child: Row(children: [
                  Icon(Icons.chat_bubble_outline,
                      color: Colors.grey.shade500, size: 20),
                  const SizedBox(width: 4),
                  Text('${post['commentsCount'] ?? 0}',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                ]),
              ),

              const Spacer(),

              // Save
              GestureDetector(
                onTap: _saved ? null : _savePost,
                child: Icon(
                  _saved ? Icons.bookmark : Icons.bookmark_border,
                  color: _saved ? Colors.deepPurple : Colors.grey.shade500,
                  size: 22,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── COMMENTS SHEET ───────────────────────────────────────────────────────────
class _CommentsSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final FirebaseService firebaseService;

  const _CommentsSheet(
      {required this.post, required this.firebaseService});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    _commentController.clear();
    try {
      await widget.firebaseService.addComment(widget.post, text);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle
        Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            const Icon(Icons.chat_bubble_outline, size: 20),
            const SizedBox(width: 8),
            Text('Comments',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ),

        const Divider(height: 1),

        // Comments list
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.firebaseService.getComments(widget.post['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No comments yet. Be first!',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade400)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final c = comments[index];
                  final avatar = c['userAvatar'] as String? ?? '';
                  final name = c['userName'] as String? ?? 'Traveler';
                  final time = c['createdAt'];
                  String timeStr = '';
                  if (time is Timestamp) {
                    final dt = time.toDate();
                    final diff = DateTime.now().difference(dt);
                    if (diff.inMinutes < 1) timeStr = 'just now';
                    else if (diff.inHours < 1) timeStr = '${diff.inMinutes}m';
                    else if (diff.inDays < 1) timeStr = '${diff.inHours}h';
                    else timeStr = '${diff.inDays}d';
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.deepPurple.shade100,
                          backgroundImage:
                              avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty
                              ? Text(name[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(name,
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                const SizedBox(width: 8),
                                Text(timeStr,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey.shade400)),
                              ]),
                              Text(c['text'] ?? '',
                                  style: GoogleFonts.poppins(fontSize: 13)),
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

        // Input bar
        Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              left: 16,
              right: 16,
              top: 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle:
                      GoogleFonts.poppins(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _send,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Colors.deepPurple, shape: BoxShape.circle),
                child: _isSending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── FOLLOW BUTTON ────────────────────────────────────────────────────────────
class _FollowButton extends StatelessWidget {
  final String targetUserId;
  final String? myUid;
  final FirebaseService firebaseService;

  const _FollowButton({
    required this.targetUserId,
    required this.myUid,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    if (myUid == null || targetUserId.isEmpty || myUid == targetUserId) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<bool>(
      stream: firebaseService.isFollowingUser(targetUserId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        
        return GestureDetector(
          onTap: () async {
            if (isFollowing) {
              await firebaseService.unfollowUser(targetUserId);
            } else {
              await firebaseService.followUser(targetUserId);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: isFollowing ? Colors.grey.shade200 : Colors.deepPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isFollowing ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── TRENDING HASHTAGS WIDGET ─────────────────────────────────────────────────
class _TrendingHashtagsWidget extends StatelessWidget {
  final FirebaseService firebaseService;
  final String? selectedTag;
  final Function(String tag) onTagSelected;

  const _TrendingHashtagsWidget({
    required this.firebaseService,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: firebaseService.getTrendingHashtags(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final tags = snapshot.data!;
        
        return Container(
          height: 36,
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tagDoc = tags[index];
              final tag = tagDoc['id'] as String;
              final count = tagDoc['count'] ?? 0;
              final isSelected = tag == selectedTag;
              
              return GestureDetector(
                onTap: () => onTagSelected(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple : Colors.white,
                    border: Border.all(color: isSelected ? Colors.deepPurple : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '#$tag',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── SUGGESTED USERS CAROUSEL ─────────────────────────────────────────────────
class _SuggestedUsersCarousel extends StatelessWidget {
  final FirebaseService firebaseService;

  const _SuggestedUsersCarousel({required this.firebaseService});

  String _reasonLabel(Map<String, dynamic> u) {
    final followers = u['followersCount'] ?? 0;
    final loc = u['preferences']?['locality'] ?? '';
    final score = u['score'] ?? 0.0;
    
    if (score > 10) return "Highly matched • $loc";
    if (loc.isNotEmpty) return "$followers followers • $loc";
    return "$followers followers";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: firebaseService.getSuggestedUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final users = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Suggested for you',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];
                  final uid = u['uid'] as String;
                  
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: u['photoUrl'] != null && u['photoUrl'].toString().isNotEmpty
                              ? NetworkImage(u['photoUrl'])
                              : null,
                          child: (u['photoUrl'] == null || u['photoUrl'].toString().isEmpty)
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          u['name'] ?? u['displayName'] ?? 'Traveler',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _reasonLabel(u),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 28,
                          child: ElevatedButton(
                            onPressed: () async {
                              await firebaseService.followUser(uid);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Following ${u['name'] ?? 'Traveler'}!"))
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Follow",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
