import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../models/trip.dart';
import '../models/app_user.dart';
import '../widgets/trip_card.dart';
import '../widgets/host_trip_bottom_sheet.dart';
import 'trip_detail_screen.dart';
import 'generated_plan_screen.dart';
import 'location_map_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('My Trips',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amber[700],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.amber,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Joined'),
            Tab(text: 'Created'),
            Tab(text: 'Planned'),
            Tab(text: 'Booked'),
            Tab(text: 'Wishlist'),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJoinedTrips(user.uid),
                _buildCreatedTrips(user.uid),
                _buildPlannedTrips(user.uid),
                _buildBookedStays(user.uid),
                _buildWishlistTrips(user.uid),
              ],
            ),
    );
  }

  Widget _buildJoinedTrips(String uid) {
    return StreamBuilder<List<String>>(
      stream: _firebaseService.getMyJoinedTripIds(uid),
      builder: (context, joinedSnapshot) {
        if (joinedSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final joinedIds = joinedSnapshot.data ?? [];
        if (joinedIds.isEmpty) {
          return _buildEmptyState(
            icon: Icons.luggage,
            title: 'No trips joined yet',
            subtitle: 'Browse the feed and join your first adventure!',
          );
        }

        return StreamBuilder<List<Trip>>(
          stream: _firebaseService.getTrips(),
          builder: (context, tripsSnapshot) {
            if (tripsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allTrips = tripsSnapshot.data ?? [];
            final joinedTrips = allTrips.where((t) => joinedIds.contains(t.id)).toList();

            if (joinedTrips.isEmpty) {
               return _buildEmptyState(
                icon: Icons.luggage,
                title: 'No trips joined yet',
                subtitle: 'Browse the feed and join your first adventure!',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: joinedTrips.length,
              itemBuilder: (context, index) {
                return TripCard(
                  trip: joinedTrips[index],
                  isJoined: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            TripDetailScreen(trip: joinedTrips[index])),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCreatedTrips(String uid) {
    return StreamBuilder<List<Trip>>(
      stream: _firebaseService.getTrips(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTrips = snapshot.data ?? [];
        final createdTrips = allTrips.where((t) => t.organizerId == uid).toList();

        if (createdTrips.isEmpty) {
          return _buildEmptyState(
            icon: Icons.add_road,
            title: 'No trips created yet',
            subtitle: 'Become an organizer — create a trip and invite others!',
            action: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const HostTripBottomSheet(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Create a Trip',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: createdTrips.length,
          itemBuilder: (context, index) {
            return TripCard(
              trip: createdTrips[index],
              isJoined: true, // You own this trip
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        TripDetailScreen(trip: createdTrips[index])),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWishlistTrips(String uid) {
    return StreamBuilder<AppUser?>(
      stream: _firebaseService.getUserProfile(uid),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
        
        final wishlistIds = userSnap.data?.wishlist ?? [];
        if (wishlistIds.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'Wishlist Empty',
            subtitle: 'Save trips you are interested in for later!',
          );
        }

        return StreamBuilder<List<Trip>>(
          stream: _firebaseService.getTrips(),
          builder: (context, tripsSnap) {
            if (!tripsSnap.hasData) return const Center(child: CircularProgressIndicator());

            final allTrips = tripsSnap.data ?? [];
            final wishlistedTrips = allTrips.where((t) => wishlistIds.contains(t.id)).toList();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: wishlistedTrips.length,
              itemBuilder: (context, index) {
                final trip = wishlistedTrips[index];
                return TripCard(
                  trip: trip,
                  showWishlist: true,
                  isWishlisted: true,
                  onWishlistToggle: () => _firebaseService.toggleWishlist(trip.id),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlannedTrips(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getCustomTripRequests(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final trips = snapshot.data ?? [];
        if (trips.isEmpty) {
          return _buildEmptyState(
            icon: Icons.map_rounded,
            title: 'No Planned Trips',
            subtitle: 'Use the Custom Trip Planner to build your dream itinerary!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            final destination = trip['destination'] ?? 'Unknown';
            final style = trip['style'] ?? 'Relaxing';
            final days = trip['days'] ?? 3;
            final status = trip['status'] ?? 'pending';

            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GeneratedPlanScreen(requestData: trip, isViewOnly: true),
                ));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flight_takeoff, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(destination, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('$days Days • $style', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'pending' ? Colors.orange[50] : Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold, 
                                color: status == 'pending' ? Colors.orange[800] : Colors.green[800]
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookedStays(String uid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getBookedStays(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stays = snapshot.data ?? [];
        if (stays.isEmpty) {
          return _buildEmptyState(
            icon: Icons.hotel,
            title: 'No Booked Stays',
            subtitle: 'Explore accommodations and book your perfect stay!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: stays.length,
          itemBuilder: (context, index) {
            final stay = stays[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => LocationMapScreen(locationData: {
                    'name': stay['location'] ?? stay['name'],
                    'image': stay['image'],
                  }),
                ));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      child: Image.network(
                        stay['image'] ?? 'https://via.placeholder.com/100',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stay['name'] ?? 'Accommodation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(stay['location'] ?? 'Location', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CONFIRMED',
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.amber[600]),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey[600])),
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action,
          ]
        ],
      ).animate().fadeIn(duration: 500.ms).scaleXY(begin: 0.95),
    );
  }
}
