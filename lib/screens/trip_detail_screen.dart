import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/firebase_service.dart';
import 'budget_tracker_screen.dart';
import 'packing_checklist_screen.dart';
import 'offline_maps_screen.dart';

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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero Image App Bar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
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
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        Text(trip.title,
                            style: GoogleFonts.poppins(
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
                                style: GoogleFonts.poppins(
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
                      _infoChip(Icons.access_time_filled,
                          '${trip.durationDays} Days', Colors.blue[50]!,
                          Colors.blue[700]!),
                      const SizedBox(width: 10),
                      _infoChip(Icons.calendar_month,
                          DateFormat('d MMM').format(trip.startDate),
                          Colors.green[50]!, Colors.green[700]!),
                      const SizedBox(width: 10),
                      _infoChip(Icons.airline_seat_recline_normal,
                          '${trip.seatsLeft} seats left',
                          trip.seatsLeft <= 2
                              ? Colors.red[50]!
                              : Colors.orange[50]!,
                          trip.seatsLeft <= 2
                              ? Colors.red[700]!
                              : Colors.orange[700]!),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 20),

                  // Budget
                  Text('Budget',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                          '₹${NumberFormat('#,##,###').format(_currentPrice())} per person',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700])),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('About this trip',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(trip.description,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6)),
                  const SizedBox(height: 20),

                  if (trip.itineraries.isNotEmpty) ...[
                    Text('Select Your Itinerary',
                        style: GoogleFonts.poppins(
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
                            color: isSelected ? Colors.amber.withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.amber : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(itinerary.title,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isSelected ? Colors.amber[800] : Colors.black87)),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: Colors.amber[700], size: 20),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(itinerary.description,
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Text('₹${NumberFormat('#,##,###').format(itinerary.price)}',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                  ],

                  // Booked Stays & Maps
                  Text('Confirmed Stays & Maps',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.hotel, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text('Luxury Villa Stay Included',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue[900])),
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
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Planning Tools
                  Text('Planning Tools',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetTrackerScreen(trip: trip)));
                          },
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Budget Tracker'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[50],
                            foregroundColor: Colors.green[800],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PackingChecklistScreen(trip: trip)));
                          },
                          icon: const Icon(Icons.checklist),
                          label: const Text('Packing List'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            foregroundColor: Colors.blue[800],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.amber[800])),
                          backgroundColor: Colors.amber.withValues(alpha: 0.1),
                          side: BorderSide(
                              color: Colors.amber.withValues(alpha: 0.4)),
                        )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Organizer Card
                  Text('Trip Organizer',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              NetworkImage(trip.organizerAvatar),
                          onBackgroundImageError: (_, __) {},
                          child: const Icon(Icons.person, size: 28, color: Colors.grey),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trip.organizerName,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text('Trip Organizer',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Connecting to ${trip.organizerName}…',
                                    style: GoogleFonts.poppins()),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline,
                              size: 16),
                          label: Text('Talk',
                              style: GoogleFonts.poppins(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber[800],
                            side: BorderSide(color: Colors.amber[300]!),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
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
                              if (mounted) {
                                if (success) {
                                  setState(() => _joined = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Joined "${trip.title}"! 🎉', style: GoogleFonts.poppins()),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to join trip.', style: GoogleFonts.poppins()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _joined ? Colors.grey[300] : Colors.amber,
                        foregroundColor:
                            _joined ? Colors.grey[600] : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: Text(
                        _joined ? 'Joined' : 'Join Trip',
                        style: GoogleFonts.poppins(
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(
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
