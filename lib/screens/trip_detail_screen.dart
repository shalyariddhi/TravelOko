import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/cached_tile_layer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/firebase_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'budget_tracker_screen.dart';
import 'packing_checklist_screen.dart';
import 'offline_maps_screen.dart';
import 'location_map_screen.dart';
import '../services/calendar_service.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _joined = false;
  String? _selectedItineraryId;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    if (widget.trip.itineraries.isNotEmpty) {
      _selectedItineraryId = widget.trip.itineraries.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Hero Image App Bar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.event_available),
                tooltip: 'Add to Calendar',
                onPressed: () => CalendarService.exportTripToICS(trip),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(trip.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (trip.isOnlyGirls)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pink[400],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Girliees',
                                style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        Text(trip.title,
                            style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(trip.destination,
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick info chips
                  Row(
                    children: [
                      _infoChip(
                        Icons.access_time_filled_rounded,
                        '${trip.durationDays} Days',
                        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                        Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 10),
                      _infoChip(
                        Icons.calendar_month_rounded,
                        DateFormat('d MMM').format(trip.startDate),
                        Theme.of(context).primaryColor.withValues(alpha: 0.08),
                        Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 10),
                      _infoChip(
                        Icons.airline_seat_recline_normal_rounded,
                        '${trip.seatsLeft} seats left',
                        trip.seatsLeft <= 2
                            ? Colors.red.withValues(alpha: 0.08)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.08),
                        trip.seatsLeft <= 2
                            ? Colors.red[700]!
                            : const Color(0xFFD97706),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 20),

                  // Budget
                  Text('Budget',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                          '₹${NumberFormat('#,##,###').format(_currentPrice())} per person',
                          style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('About this trip',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(trip.description,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFF5C6F84),
                          height: 1.6)),
                  const SizedBox(height: 20),

                  if (trip.itineraries.isNotEmpty) ...[
                    Text('Select Your Itinerary',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    ...trip.itineraries.map((itinerary) {
                      final isSelected = _selectedItineraryId == itinerary.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedItineraryId = itinerary.id;
                          });
                        },
                        child: AnimatedContainer(
                          duration: 300.ms,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Theme.of(context).primaryColor : const Color(0xFFEFF1F6),
                              width: isSelected ? 2 : 1.2,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ] : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(itinerary.title,
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF0F172A))),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded, color: Theme.of(context).primaryColor, size: 22),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(itinerary.description,
                                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF5C6F84))),
                              const SizedBox(height: 8),
                              Text('₹${NumberFormat('#,##,###').format(itinerary.price)}',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A))),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Interactive Map & Stays
                  Text('Trip Location & Stays',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (trip.lat != null && trip.lng != null)
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(trip.lat!, trip.lng!),
                                initialZoom: 12,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                                ),
                              ),
                              children: [
                                cachedTileLayer(),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(trip.lat!, trip.lng!),
                                      width: 60,
                                      height: 60,
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        size: 40,
                                        color: Theme.of(context).primaryColor,
                                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.2, duration: 800.ms),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.hotel_rounded, color: Colors.white, size: 16),
                                            const SizedBox(width: 6),
                                            Text('Luxury Villa Stay', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => LocationMapScreen(
                                              locationData: {
                                                'name': trip.destination,
                                                'lat': trip.lat,
                                                'lng': trip.lng,
                                              },
                                            )));
                                          },
                                          icon: const Icon(Icons.fullscreen_rounded, size: 16),
                                          label: Text('Expand Map', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.secondary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                            minimumSize: const Size(0, 32),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1)
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.hotel_rounded, color: Theme.of(context).colorScheme.secondary, size: 20),
                              const SizedBox(width: 8),
                              Text('Luxury Villa Stay Included',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => OfflineMapsScreen(destination: trip.destination)));
                              },
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Download Offline Map & Stays'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Planning Tools
                  Text('Planning Tools',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetTrackerScreen(trip: trip)));
                          },
                          icon: const Icon(Icons.account_balance_wallet_rounded),
                          label: const Text('Budget Tracker'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                            foregroundColor: Theme.of(context).primaryColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PackingChecklistScreen(trip: trip)));
                          },
                          icon: const Icon(Icons.checklist_rounded),
                          label: const Text('Packing List'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                            foregroundColor: Theme.of(context).colorScheme.secondary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: trip.tags.map((tag) => Chip(
                          label: Text(tag,
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
                          backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Organizer Card
                  Text('Trip Organizer',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFEFF1F6), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFEFF1F6),
                          backgroundImage:
                              NetworkImage(trip.organizerAvatar),
                          onBackgroundImageError: (_, __) {},
                          child: const Icon(Icons.person, size: 28, color: Color(0xFF8A99AD)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trip.organizerName,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: const Color(0xFF0F172A))),
                              Text('Trip Organizer',
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, color: const Color(0xFF8A99AD))),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Connecting to ${trip.organizerName}…',
                                    style: GoogleFonts.outfit()),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 16),
                          label: Text('Talk',
                              style: GoogleFonts.outfit(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 32),

                  // Join Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _joined
                          ? null
                          : () async {
                              final success = await _firebaseService.joinTrip(
                                trip.id,
                                itineraryId: _selectedItineraryId,
                              );
                              if (!context.mounted) return;
                              if (success) {
                                setState(() => _joined = true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Joined "${trip.title}"! 🎉', style: GoogleFonts.outfit()),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to join trip.', style: GoogleFonts.outfit()),
                                      backgroundColor: Colors.red,
                                    ),
                                    );
                                  }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _joined ? const Color(0xFFEFF1F6) : Theme.of(context).primaryColor,
                        foregroundColor:
                            _joined ? const Color(0xFF8A99AD) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: _joined ? 0 : 8,
                        shadowColor: _joined ? Colors.transparent : Theme.of(context).primaryColor.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        _joined ? 'Joined' : 'Join Trip',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ).animate(
                      onPlay: (c) =>
                          _joined ? null : c.repeat(reverse: true),
                    ).scaleXY(
                      begin: 1.0,
                      end: 1.03,
                      duration: 900.ms,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(
      IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      ]),
    );
  }

  int _currentPrice() {
    if (widget.trip.itineraries.isEmpty) return widget.trip.budget;
    if (_selectedItineraryId == null) return widget.trip.budget;
    try {
      return widget.trip.itineraries.firstWhere((i) => i.id == _selectedItineraryId).price;
    } catch (_) {
      return widget.trip.budget;
    }
  }
}
