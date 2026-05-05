import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/places_api_service.dart';
import 'accommodations_screen.dart';
import 'map_intro_screen.dart';

class LocationMapScreen extends StatefulWidget {
  final Map<String, dynamic> locationData;

  const LocationMapScreen({super.key, required this.locationData});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final PlacesApiService _placesApiService = PlacesApiService();

  List<Map<String, dynamic>> _nearbyPlaces = [];
  List<Map<String, dynamic>> _localStays = [];
  bool _isLoading = true;

  // Dark mode map style
  static const String _darkMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
    {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
    {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#023e58"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
    {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
    {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _loadNearbyData();
  }

  Future<void> _loadNearbyData() async {
    final locationName = widget.locationData['name'] ?? 'India';
    final results = await Future.wait([
      _placesApiService.fetchLocations('tourist attractions near $locationName India'),
      _placesApiService.fetchAccommodations(locationName),
    ]);

    if (mounted) {
      setState(() {
        _nearbyPlaces = results[0].take(5).toList();
        _localStays = results[1].take(4).toList();
        _isLoading = false;
      });
    }
  }

  LatLng get _destination {
    final lat = widget.locationData['lat'];
    final lng = widget.locationData['lng'];
    if (lat != null && lng != null) {
      return LatLng((lat as num).toDouble(), (lng as num).toDouble());
    }
    return const LatLng(20.5937, 78.9629); // Centre of India fallback
  }

  @override
  Widget build(BuildContext context) {
    final locationName = widget.locationData['name'] ?? 'Unknown Location';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // ── 1. Interactive Google Map Background ──
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _destination,
                zoom: 11,
                tilt: 45,
                bearing: 20,
              ),
              onMapCreated: (controller) {
                _mapController.complete(controller);
              },
              style: _darkMapStyle,
              markers: {
                Marker(
                  markerId: MarkerId(locationName),
                  position: _destination,
                  infoWindow: InfoWindow(title: locationName),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                ),
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // ── 2. Gradient overlay at top so AppBar is visible ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── 3. Location Name Label floating on map ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          locationName.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.5, end: 0),
          ),

          // ── 4. Draggable Bottom Sheet ──
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Header
                        Text(
                          'Explore $locationName',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                        ).animate().slideX(duration: 400.ms),
                        const SizedBox(height: 6),
                        Text(
                          'Discover top spots, hidden gems, and the best stays.',
                          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                        ),
                        const SizedBox(height: 24),

                        // Plan a Trip Button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MapIntroScreen()));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.amber[700]!, Colors.amber[400]!]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit_calendar_rounded, color: Colors.black87),
                                const SizedBox(width: 8),
                                Text('Plan a Custom Trip Here',
                                    style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ).animate().scaleXY(begin: 0.9, end: 1.0, duration: 500.ms, curve: Curves.easeOutBack),

                        const SizedBox(height: 30),

                        // ── Places to Visit ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Places to Visit', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('See All', style: GoogleFonts.poppins(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _isLoading
                            ? SizedBox(
                                height: 160,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 4,
                                  itemBuilder: (context, i) => Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                                      .shimmer(duration: 1.2.seconds, color: Colors.white.withValues(alpha: 0.05)),
                                ),
                              )
                            : SizedBox(
                                height: 160,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _nearbyPlaces.length,
                                  itemBuilder: (context, index) {
                                    final place = _nearbyPlaces[index];
                                    return Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.blueGrey[900],
                                        image: DecorationImage(
                                          image: NetworkImage(place['image']),
                                          fit: BoxFit.cover,
                                          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.35), BlendMode.darken),
                                          onError: (_, __) {},
                                        ),
                                      ),
                                      alignment: Alignment.bottomLeft,
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        place['name'],
                                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
                                  },
                                ),
                              ),

                        const SizedBox(height: 30),

                        // ── Top Stays ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Top Stays', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccommodationsScreen())),
                              child: Text('Book Now', style: GoogleFonts.poppins(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator(color: Colors.amber))
                        else
                          ..._localStays.map((stay) => _buildStayCard(stay)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStayCard(Map<String, dynamic> stay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            child: Image.network(
              stay['image'] ?? '',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120, height: 120, color: Colors.grey[800],
                child: const Icon(Icons.hotel, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stay['name'] ?? '', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('${stay['rating']} (${stay['reviews']})', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(stay['price'] ?? '', style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}
