import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trip.dart';
import '../widgets/trip_card.dart';
import '../services/firebase_service.dart';
import 'trip_detail_screen.dart';
import 'map_intro_screen.dart';
import 'category_destinations_screen.dart';
import 'explore_screen.dart';
import 'location_map_screen.dart';
import '../models/app_user.dart';
import '../data/mock_data.dart';
import '../services/places_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PlacesApiService _placesApiService = PlacesApiService();
  AppUser? _currentUserData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _firebaseService.currentUser;
    if (user != null) {
      _firebaseService.getUserProfile(user.uid).listen((appUser) {
        if (mounted && appUser != null) {
          setState(() {
            _currentUserData = appUser;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildFeaturedBanner(),
          _buildDiscoverySections(),
          _buildFeed(),
        ],
      ),
      floatingActionButton: _buildPlanFAB(),
    );
  }

  Widget _buildPlanFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'planBtn',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapIntroScreen())),
        backgroundColor: Colors.amber[700],
        icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
        label: Text('Plan My Trip',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.05, duration: 900.ms),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: false,
      backgroundColor: const Color(0xFFF6F7F9),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF6F7F9)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('NAMASTE 🙏',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.amber[800], fontWeight: FontWeight.bold)),
                  Text('Your Travel Feed',
                      style: GoogleFonts.poppins(
                          fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87)),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
              if (_currentUserData != null)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Colors.amber, Color(0xFFFF6B6B)]),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage((_currentUserData!.photoUrl.isNotEmpty && !_currentUserData!.photoUrl.contains('pravatar'))
                        ? _currentUserData!.photoUrl
                        : 'https://api.dicebear.com/9.x/avataaars/png?seed=${_currentUserData!.uid}'),
                    onBackgroundImageError: (e, s) {},
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedBanner() {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen(showOnlyTrips: true)));
        },
        child: Container(
        height: 180,
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1524492412937-b28074a5d7da?auto=format&fit=crop&w=1000&q=80'), // Beautiful India landscape
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dark gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.2), Colors.transparent],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            // Decorative elements
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.15),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(duration: 2.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('🌟 TRAVEL INDIA',
                        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
                  const SizedBox(height: 8),
                  Text('Explore India Together',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, height: 1.1, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.group, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text('Join 1,200+ travelers',
                          style: GoogleFonts.poppins(color: Colors.grey[200], fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            // Floating action button style arrow
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.black87, size: 20),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveX(begin: 0, end: 5, duration: 1.seconds),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
      ),
    );
  }

  Widget _buildDiscoverySections() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHorizontalListStream('🔥 Trending Destinations', 'What\'s hot right now', Stream.fromFuture(_placesApiService.fetchLocations('Top trending tourist attractions in India'))),
          _buildHorizontalListStream('🌸 Seasonal Guide', 'Perfect places for this season', Stream.fromFuture(_placesApiService.fetchLocations('Beautiful hill stations in India'))),
          _buildHorizontalListStream('💎 Hidden Gems', 'Lesser-known local favorites', Stream.fromFuture(_placesApiService.fetchLocations('Offbeat hidden gems and nature in India'))),
        ],
      ),
    );
  }

  Widget _buildHorizontalListStream(String title, String subtitle, Stream<List<Map<String, dynamic>>> stream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data!;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  // Ensure category destinations screen works with dynamic maps
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CategoryDestinationsScreen(
                      title: title,
                      subtitle: subtitle,
                      locations: items.map((e) => e.map((key, value) => MapEntry(key, value.toString()))).toList(),
                    ),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final location = items[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => LocationMapScreen(locationData: location),
                        ));
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(location['image'] ?? 'https://via.placeholder.com/150'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          location['name'] ?? 'Unknown',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildFeed() {
    if (_currentUserData == null) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return StreamBuilder<List<Trip>>(
      stream: _firebaseService.getFeedTrips(_currentUserData!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(child: Text('Error loading feed', style: GoogleFonts.poppins(color: Colors.white70))),
          );
        }

        List<Trip> trips = snapshot.data ?? <Trip>[];

        if (trips.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dynamic_feed_rounded, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Your feed is quiet',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Follow more travelers or check out the Explore tab to find new adventures.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return TripCard(
                  trip: trips[index],
                  showWishlist: true,
                  isWishlisted: _currentUserData!.wishlist.contains(trips[index].id),
                  onWishlistToggle: () => _firebaseService.toggleWishlist(trips[index].id),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trips[index])),
                  ),
                  onJoin: () async {
                    final success = await _firebaseService.joinTrip(trips[index].id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'Joined "${trips[index].title}"! 🎉' : 'Failed to join. It might be full.',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: success ? const Color(0xFF00C853) : Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: (index * 80).ms)
                    .slideY(begin: 0.08, end: 0);
              },
              childCount: trips.length,
            ),
          ),
        );
      },
    );
  }
}
