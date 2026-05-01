import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/mock_data.dart';
import 'accommodations_screen.dart';
import 'map_intro_screen.dart';

class LocationMapScreen extends StatefulWidget {
  final Map<String, dynamic> locationData;

  const LocationMapScreen({super.key, required this.locationData});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  @override
  Widget build(BuildContext context) {
    final locationName = widget.locationData['name'] ?? 'Unknown Location';
    final locationImage = widget.locationData['image'] ?? 'https://via.placeholder.com/400';

    // Get stays for this location (or some random ones if none found)
    List<Map<String, dynamic>> localStays = MockData.accommodations
        .where((stay) => stay['location'].toString().contains(locationName))
        .toList();
    
    if (localStays.isEmpty) {
      localStays = MockData.accommodations.take(5).toList(); // fallback
    }

    // Mock Nearby places
    final List<Map<String, String>> nearbyPlaces = [
      {'name': 'Sunset Point', 'image': 'https://images.unsplash.com/photo-1506501139174-099022df5260?auto=format&fit=crop&w=500&q=80'},
      {'name': 'Local Market', 'image': 'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?auto=format&fit=crop&w=500&q=80'},
      {'name': 'Ancient Temple', 'image': 'https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&w=500&q=80'},
      {'name': 'Hidden Waterfall', 'image': 'https://images.unsplash.com/photo-1590050752117-238cb0fb12b1?auto=format&fit=crop&w=500&q=80'},
    ];

    return Scaffold(
      backgroundColor: Colors.black, // Dark sleek theme
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Beautiful Map/Location Background
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 3.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base blurred image as "map" terrain
                  Image.network(
                    locationImage,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity, height: double.infinity, color: Colors.blueGrey[900],
                    ),
                  ),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Map grid pattern
                  CustomPaint(
                    size: Size.infinite,
                    painter: GridPainter(),
                  ),
                  // The glowing animated Pin
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulse rings
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber.withValues(alpha: 0.2),
                              ),
                            ).animate(onPlay: (c) => c.repeat()).scaleXY(begin: 0.5, end: 1.5, duration: 2.seconds).fadeOut(duration: 2.seconds),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber.withValues(alpha: 0.4),
                              ),
                            ).animate(onPlay: (c) => c.repeat()).scaleXY(begin: 0.5, end: 1.2, duration: 1.5.seconds).fadeOut(duration: 1.5.seconds),
                            
                            // Actual Pin Center
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(color: Colors.amber.withValues(alpha: 0.8), blurRadius: 15, spreadRadius: 5),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Label
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                locationName.toUpperCase(),
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                              ),
                            ),
                          ),
                        ).animate().slideY(begin: 1, end: 0, duration: 600.ms).fadeIn(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Draggable Bottom Sheet for Exploration
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
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
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
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                        ).animate().slideX(duration: 400.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Discover the best spots, hidden gems, and top stays in this amazing destination.',
                          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                        ),
                        const SizedBox(height: 24),

                        // Plan a Trip Action Button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MapIntroScreen()));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber[700]!, Colors.amber[400]!],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit_calendar_rounded, color: Colors.black87),
                                const SizedBox(width: 8),
                                Text(
                                  'Plan a Custom Trip Here',
                                  style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ).animate().scaleXY(begin: 0.9, end: 1.0, duration: 500.ms, curve: Curves.easeOutBack),
                        
                        const SizedBox(height: 30),

                        // Nearby Places Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Places to Visit', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('See All', style: GoogleFonts.poppins(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: nearbyPlaces.length,
                            itemBuilder: (context, index) {
                              final place = nearbyPlaces[index];
                              return Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: NetworkImage(place['image']!),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                                    onError: (error, stackTrace) {}, // Ignore errors and just show background
                                  ),
                                ),
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  place['name']!,
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
                            },
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Stays Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Top Stays', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AccommodationsScreen()));
                              },
                              child: Text('Book Now', style: GoogleFonts.poppins(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...localStays.map((stay) => _buildStayCard(stay)).toList(),
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
              stay['image'] ?? 'https://via.placeholder.com/100',
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
                  Text(stay['name'] ?? '', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('${stay['rating']} (${stay['reviews']} reviews)', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(stay['price'] ?? '', style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

// Custom Painter for Map Grid overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
