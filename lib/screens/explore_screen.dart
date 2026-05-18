import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/trip.dart';
import '../models/app_user.dart';
import '../data/mock_data.dart';
import '../widgets/trip_card.dart';
import '../services/firebase_service.dart';
import 'trip_detail_screen.dart';
import 'accommodations_screen.dart';
import 'profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  final bool showOnlyTrips;

  const ExploreScreen({super.key, this.showOnlyTrips = false});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  String _query = '';
  List<AppUser> _userResults = [];
  bool _isSearchingUsers = false;
  bool _isOnlyGirlsMode = false;
  String _userGender = 'unknown';
  AppUser? _currentUserData;

  // Filters from old Home Screen
  int _maxBudget = 100000;
  int _maxDuration = 30;
  bool _onlyGirls = false;
  int _selectedCategory = 0;
  final List<Map<String, dynamic>> _categories = MockData.categories;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Clear search when switching tabs
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        setState(() {
          _query = '';
          _userResults = [];
        });
      }
    });
    // Pre-load all users
    _searchPeople('');
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      _firebaseService.getUserProfile(user.uid).listen((appUser) {
        if (mounted && appUser != null) {
          setState(() {
            _currentUserData = appUser;
            _userGender = appUser.gender;
            _isOnlyGirlsMode = appUser.isOnlyGirlsMode && appUser.gender.toLowerCase() == 'female';
            if (_userGender.toLowerCase() != 'female') {
              _onlyGirls = false;
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPeople(String q) async {
    setState(() => _isSearchingUsers = true);
    final results = await _firebaseService.searchUsers(q);
    if (mounted) {
      setState(() {
        _userResults = results;
        _isSearchingUsers = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    if (_tabController.index == 1) {
      // People tab
      _searchPeople(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header + Search ──
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.showOnlyTrips)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFF4500)],
                                ).createShader(bounds),
                                child: Text(
                                  widget.showOnlyTrips ? 'Community Trips' : 'Discover India',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Text(
                                'Explore endless adventures across the country',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white38
                                      : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Premium search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: (widget.showOnlyTrips || _tabController.index == 0)
                              ? 'Search trips, destinations in India…'
                              : _tabController.index == 1
                                  ? 'Search people by name…'
                                  : 'Find your perfect stay…',
                          hintStyle: GoogleFonts.outfit(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white30
                                : Colors.black38,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white30
                                : Colors.black38,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  })
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (!widget.showOnlyTrips) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white38
                              : Colors.black38,
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8C00), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8C00).withValues(alpha: 0.4),
                                blurRadius: 12,
                              )
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w400, fontSize: 13),
                          onTap: (_) {
                            setState(() {});
                            if (_tabController.index == 1 && _query.isEmpty) {
                              _searchPeople('');
                            }
                          },
                          tabs: const [
                            Tab(text: '✈️  Trips'),
                            Tab(text: '👥  People'),
                            Tab(text: '🏨  Stays'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
              ),
            ),

            // ── Tab content ──
            Expanded(
              child: widget.showOnlyTrips
                ? _buildTripsTab()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTripsTab(),
                      _buildPeopleTab(),
                      AccommodationsScreen(
                        isEmbedded: true,
                        initialQuery: _tabController.index == 2 ? _query : '',
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Trips tab ──────────────────────────────────────────────
  Widget _buildTripsTab() {
    return CustomScrollView(
      slivers: [
        _buildCategoryBar(),
        _buildFilterRow(),
        _buildTripsFeed(),
      ],
    );
  }

  Widget _buildCategoryBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final selected = _selectedCategory == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? Colors.amber : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Text(
                    '${_categories[index]['icon']} ${_categories[index]['label']}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            },
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterHeaderDelegate(
        child: Container(
          color: const Color(0xFFF6F7F9),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  label: '₹ ≤ ${_maxBudget == 100000 ? "Any" : "₹$_maxBudget"}',
                  icon: Icons.currency_rupee,
                  onTap: _showBudgetFilter,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: '⏱ ≤ ${_maxDuration == 30 ? "Any" : "$_maxDuration days"}',
                  icon: Icons.access_time,
                  onTap: _showDurationFilter,
                ),
                const SizedBox(width: 8),
                if (_userGender.toLowerCase() == 'female')
                  FilterChip(
                  label: Text('Girliees',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _onlyGirls
                              ? Colors.pink[700]
                              : Colors.grey[700])),
                  selected: _onlyGirls,
                  onSelected: (v) => setState(() => _onlyGirls = v),
                  selectedColor: Colors.pink[100],
                  checkmarkColor: Colors.pink,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                          color: _onlyGirls
                              ? Colors.pink
                              : Colors.grey[300]!)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(
      {required String label,
      required IconData icon,
      required VoidCallback onTap}) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: Colors.amber[700]),
      label: Text(label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
      onPressed: onTap,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey[300]!)),
    );
  }

  Widget _buildTripsFeed() {
    return StreamBuilder<List<Trip>>(
      stream: _firebaseService.getTrips(
        maxBudget: _maxBudget == 100000 ? null : _maxBudget,
        maxDuration: _maxDuration == 30 ? null : _maxDuration,
        onlyGirls: (_onlyGirls || _isOnlyGirlsMode) ? true : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins())),
          );
        }

        List<Trip> allTrips = snapshot.data ?? <Trip>[];

        // Apply category filter locally
        if (_selectedCategory != 0) {
          final catLabel = _categories[_selectedCategory]['label'].toString().toLowerCase();
          allTrips = allTrips.where((t) => t.tags.any((tag) => tag.toLowerCase() == catLabel)).toList();
        }

        // Filter by search query
        if (_query.isNotEmpty) {
          final q = _query.toLowerCase();
          allTrips = allTrips.where((t) {
            return t.title.toLowerCase().contains(q) ||
                t.destination.toLowerCase().contains(q) ||
                t.tags.any((tag) => tag.toLowerCase().contains(q));
          }).toList();
        }

        if (allTrips.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.search_off,
              message: _query.isEmpty
                  ? 'No trips match your filters'
                  : 'No trips found for "$_query"',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return TripCard(
                  trip: allTrips[index],
                  showWishlist: _currentUserData != null,
                  isWishlisted: _currentUserData?.wishlist.contains(allTrips[index].id) ?? false,
                  onWishlistToggle: () {
                    if (_currentUserData != null) {
                      _firebaseService.toggleWishlist(allTrips[index].id);
                    }
                  },
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            TripDetailScreen(trip: allTrips[index])),
                  ),
                  onJoin: () async {
                    final success = await _firebaseService.joinTrip(allTrips[index].id);
                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Joined "${allTrips[index].title}"! 🎉',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Failed to join trip. It might be full.',
                              style: GoogleFonts.poppins()),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (index * 60).ms)
                    .slideY(begin: 0.06);
              },
              childCount: allTrips.length,
            ),
          ),
        );
      },
    );
  }

  // ── People tab ─────────────────────────────────────────────
  Widget _buildPeopleTab() {
    if (_isSearchingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    List<AppUser> filteredUsers = _userResults;
    if (_isOnlyGirlsMode) {
      filteredUsers = filteredUsers.where((u) => u.gender.toLowerCase() == 'female').toList();
    }

    if (filteredUsers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_search,
        message: _query.isEmpty
            ? 'No travelers found yet'
            : 'No one found for "$_query"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user, index);
      },
    );
  }

  Widget _buildUserCard(AppUser user, int index) {
    final avatarUrl = user.photoUrl.isNotEmpty
        ? user.photoUrl
        : 'https://api.dicebear.com/9.x/avataaars/png?seed=${user.uid}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(targetUserId: user.uid),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2.5),
              ),
              child: ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName
                              : 'Traveler',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.verifiedScore >= 70) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            color: Colors.blue, size: 16),
                      ],
                    ],
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      user.bio,
                      style: GoogleFonts.poppins(
                          color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Stats row
                  Row(
                    children: [
                      _userStat(Icons.luggage_outlined,
                          '${user.tripsCount} trips'),
                      const SizedBox(width: 12),
                      _userStat(Icons.people_outline,
                          '${user.followersCount} followers'),
                      const SizedBox(width: 12),
                      // Trust score badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _trustColor(user.verifiedScore)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield,
                                color: _trustColor(user.verifiedScore),
                                size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '${user.verifiedScore}%',
                              style: GoogleFonts.poppins(
                                color: _trustColor(user.verifiedScore),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    ),
  ).animate()
   .fadeIn(duration: 400.ms, delay: (index * 60).ms)
   .slideX(begin: 0.05);
  }

  Widget _userStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(label,
            style:
                GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }

  Color _trustColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message,
              style:
                  GoogleFonts.poppins(color: Colors.grey[500], fontSize: 15)),
        ],
      ).animate().fadeIn(),
    );
  }

  void _showBudgetFilter() {
    int temp = _maxBudget;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setModal) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Max Budget',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                temp == 100000 ? 'Any' : '₹${temp.toString()}',
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber)),
            Slider(
              value: temp.toDouble(),
              min: 5000,
              max: 100000,
              divisions: 19,
              activeColor: Colors.amber,
              onChanged: (v) => setModal(() => temp = v.toInt()),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _maxBudget = temp);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text('Apply',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ]),
        );
      }),
    );
  }

  void _showDurationFilter() {
    int temp = _maxDuration;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setModal) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Max Duration',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                temp == 30 ? 'Any' : '$temp Days',
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber)),
            Slider(
              value: temp.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: Colors.amber,
              onChanged: (v) => setModal(() => temp = v.toInt()),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _maxDuration = temp);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: Text('Apply',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ]),
        );
      }),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _FilterHeaderDelegate({required this.child});

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
