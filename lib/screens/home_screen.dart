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
import 'paywall_screen.dart';
import '../services/remote_config_service.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          _buildFeaturedBanner(context),
          _buildDiscoverySections(context),
          _buildFeed(context),
        ],
      ),
      floatingActionButton: _buildPlanFAB(context),
    );
  }

  Widget _buildPlanFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'planBtn',
        onPressed: () {
          if (_currentUserData != null && !_currentUserData!.isPro &&
              _currentUserData!.tripsCount >= RemoteConfigService().freeTripLimit) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MapIntroScreen()));
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: Icon(Icons.edit_calendar_rounded, color: Theme.of(context).colorScheme.onPrimary),
        label: Text('Plan My Trip',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.04, duration: 1200.ms),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Theme.of(context).colorScheme.surface, Theme.of(context).scaffoldBackgroundColor],
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
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFF4500)],
                    ).createShader(bounds),
                    child: Text('GO-Trivo',
                        style: GoogleFonts.outfit(
                            fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  ),
                  Text('Discover • Plan • Explore',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Theme.of(context).primaryColor.withValues(alpha: 0.8), fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
              if (_currentUserData != null)
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Theme.of(context).primaryColor, const Color(0xFFFF6B9D)],
                    ),
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

  Widget _buildFeaturedBanner(BuildContext context) {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen(showOnlyTrips: true)));
        },
        child: Container(
          height: 200,
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1524492412937-b28074a5d7da?auto=format&fit=crop&w=1000&q=80'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.75), Colors.black.withValues(alpha: 0.15), Colors.transparent],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 2.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('🌟 TRAVEL INDIA',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
                    const SizedBox(height: 8),
                    Text('Explore India Together',
                        style: GoogleFonts.outfit(
                            color: Colors.white, fontSize: 24, height: 1.1, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.group, color: Theme.of(context).primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text('Join 1,200+ travelers',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(Icons.arrow_forward, color: Theme.of(context).primaryColor, size: 20),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(begin: 0, end: 5, duration: 1.seconds),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
      ),
    );
  }

  Widget _buildDiscoverySections(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHorizontalListSection(
            context,
            '🔥 Trending Destinations',
            "What's hot right now",
            MockData.trendingDestinations,
            liveQuery: 'Top trending tourist attractions in India',
          ),
          _buildHorizontalListSection(
            context,
            '🌸 Seasonal Guide',
            'Perfect places for this season',
            MockData.seasonalGuide,
            liveQuery: 'Beautiful hill stations in India',
          ),
          _buildHorizontalListSection(
            context,
            '💎 Hidden Gems',
            'Lesser-known local favorites',
            MockData.hiddenGems,
            liveQuery: 'Offbeat hidden gems and nature in India',
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalListSection(
    BuildContext context,
    String title,
    String subtitle,
    List<Map<String, String>> fallbackItems, {
    required String liveQuery,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _placesApiService.fetchLocations(liveQuery),
      builder: (context, snapshot) {
        // Merge live + fallback: prefer live if available, else use mock data
        final List<Map<String, dynamic>> items;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          items = snapshot.data!;
        } else {
          // Convert mock Map<String,String> to Map<String,dynamic>
          items = fallbackItems
              .map((e) => <String, dynamic>{
                    'name': e['name'] ?? '',
                    'image': e['image'] ?? '',
                    'lat': null,
                    'lng': null,
                  })
              .toList();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDestinationsScreen(
                        title: title,
                        subtitle: subtitle,
                        locations: items
                            .map((e) => e.map((k, v) => MapEntry(k, v?.toString() ?? '')))
                            .toList(),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).textTheme.bodyLarge?.color)),
                          Text(subtitle,
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodyMedium?.color)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text('See all',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF8C00))),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 11, color: Color(0xFFFF8C00)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final location = items[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationMapScreen(locationData: location),
                          ),
                        );
                      },
                      child: Container(
                        width: 148,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: const Color(0xFF1A1A2E),
                          image: (location['image'] != null &&
                                  (location['image'] as String).isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(location['image']),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // Gradient overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                    stops: const [0.35, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            if (location['image'] == null || (location['image'] as String).isEmpty)
                              const Center(
                                child: Icon(Icons.location_city_rounded, color: Colors.white54, size: 36),
                              ),
                            // Name at bottom
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: Text(
                                location['name'] ?? 'Unknown',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: (index * 60).ms).slideX(begin: 0.1),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeed(BuildContext context) {
    if (_currentUserData == null) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
      );
    }

    return StreamBuilder<List<Trip>>(
      stream: _firebaseService.getFeedTrips(_currentUserData!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
          );
        }
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(child: Text('Error loading feed', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color))),
          );
        }

        List<Trip> trips = snapshot.data ?? <Trip>[];

        if (trips.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ),
                    child: Icon(Icons.dynamic_feed_rounded, size: 56, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 20),
                  Text('Your feed is quiet',
                      style: GoogleFonts.outfit(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Follow more travelers or check out the Explore tab.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
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
