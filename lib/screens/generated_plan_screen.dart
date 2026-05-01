import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class GeneratedPlanScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final bool isViewOnly;

  const GeneratedPlanScreen({super.key, required this.requestData, this.isViewOnly = false});

  @override
  State<GeneratedPlanScreen> createState() => _GeneratedPlanScreenState();
}

class _GeneratedPlanScreenState extends State<GeneratedPlanScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isGenerating = true;
  bool _isSaving = false;

  late List<Map<String, dynamic>> _itineraryDays;

  @override
  void initState() {
    super.initState();
    if (widget.isViewOnly && widget.requestData.containsKey('generatedItinerary')) {
      _itineraryDays = List<Map<String, dynamic>>.from(widget.requestData['generatedItinerary'] ?? []);
      _isGenerating = false;
    } else {
      _generateMockItinerary();
    }
  }

  void _generateMockItinerary() async {
    final destination = widget.requestData['destination'] as String;
    final days = widget.requestData['days'] as int;
    final style = widget.requestData['style'] as String;

    _itineraryDays = List.generate(days, (index) {
      if (index == 0) {
        return {
          'title': 'Arrival & Check-in',
          'description': 'Welcome to $destination! Settle in and explore the nearby areas.',
          'timeline': [
            {'time': '02:00 PM', 'activity': 'Check into your premium accommodation'},
            {'time': '05:30 PM', 'activity': 'Evening stroll around the local market square'},
            {'time': '08:00 PM', 'activity': 'Welcome dinner at a highly-rated authentic restaurant'},
          ]
        };
      } else if (index == days - 1) {
        return {
          'title': 'Departure',
          'description': 'Time to say goodbye to $destination. Safe travels!',
          'timeline': [
            {'time': '09:00 AM', 'activity': 'Enjoy a relaxed morning breakfast at the hotel'},
            {'time': '11:00 AM', 'activity': 'Pick up some local souvenirs and pack your bags'},
            {'time': '02:00 PM', 'activity': 'Transfer to the airport / station'},
          ]
        };
      } else {
        List<Map<String, String>> timeline = [];
        if (style == 'Adventure') {
          timeline = [
            {'time': '07:00 AM', 'activity': 'Early morning hike to the scenic sunrise point'},
            {'time': '12:00 PM', 'activity': 'Adrenaline-pumping water sports or paragliding'},
            {'time': '06:00 PM', 'activity': 'Bonfire and camping dinner'},
          ];
        } else if (style == 'Relaxing') {
          timeline = [
            {'time': '10:00 AM', 'activity': 'Rejuvenating 2-hour spa session'},
            {'time': '01:00 PM', 'activity': 'Lunch by the serene beachfront or valley cafe'},
            {'time': '05:00 PM', 'activity': 'Sunset watching with a mocktail'},
          ];
        } else if (style == 'Cultural') {
          timeline = [
            {'time': '09:00 AM', 'activity': 'Guided tour of the Grand Heritage Museum'},
            {'time': '02:00 PM', 'activity': 'Visit the ancient temple ruins and historical monuments'},
            {'time': '07:00 PM', 'activity': 'Local folk dance and cultural show'},
          ];
        } else {
          // Party
          timeline = [
            {'time': '11:00 AM', 'activity': 'Late breakfast and relaxing at a beach club'},
            {'time': '04:00 PM', 'activity': 'Sunset boat party with live DJ'},
            {'time': '10:00 PM', 'activity': 'Club hopping through the famous nightlife street'},
          ];
        }
        return {
          'title': 'Day ${index + 1} - $style Experience',
          'description': 'A full day of $style activities curated just for you.',
          'timeline': timeline,
        };
      }
    });

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }

  /// Returns a list of mock nearby hotels/hostels based on the destination keyword.
  List<Map<String, dynamic>> _getNearbyStays(String destination) {
    final dest = destination.toLowerCase();

    // Destination-specific stays
    final Map<String, List<Map<String, dynamic>>> stayMap = {
      'goa': [
        {'name': 'Beach Shack Stays', 'type': 'Hostel', 'price': '₹1,200', 'rating': 4.6, 'icon': '🏖️', 'color': const Color(0xFF00B4DB)},
        {'name': 'Palolem Paradise Inn', 'type': 'Hotel', 'price': '₹4,800', 'rating': 4.4, 'icon': '🌊', 'color': const Color(0xFF2193b0)},
        {'name': 'Anjuna Hippie Hostel', 'type': 'Hostel', 'price': '₹900', 'rating': 4.3, 'icon': '🎸', 'color': const Color(0xFF6A11CB)},
      ],
      'manali': [
        {'name': 'Cozy Himalayan Cabin', 'type': 'Rental', 'price': '₹3,200', 'rating': 4.8, 'icon': '🏔️', 'color': const Color(0xFF134E5E)},
        {'name': 'Snow Peak Hostel', 'type': 'Hostel', 'price': '₹800', 'rating': 4.5, 'icon': '❄️', 'color': const Color(0xFF1e3c72)},
        {'name': 'The Manali Inn', 'type': 'Hotel', 'price': '₹3,500', 'rating': 4.3, 'icon': '🌲', 'color': const Color(0xFF2d6a4f)},
      ],
      'udaipur': [
        {'name': 'Taj Lake Palace', 'type': 'Hotel', 'price': '₹14,500', 'rating': 4.9, 'icon': '⭐', 'color': const Color(0xFFED8F03)},
        {'name': 'Zostel Udaipur', 'type': 'Hostel', 'price': '₹700', 'rating': 4.4, 'icon': '🏰', 'color': const Color(0xFF6A11CB)},
        {'name': 'Heritage Haveli Suite', 'type': 'Hotel', 'price': '₹5,200', 'rating': 4.6, 'icon': '🎡', 'color': const Color(0xFFf7971e)},
      ],
      'kasol': [
        {'name': 'The Backpacker Den', 'type': 'Hostel', 'price': '₹850', 'rating': 4.5, 'icon': '🔥', 'color': const Color(0xFF6A11CB)},
        {'name': 'Parvati Valley Camp', 'type': 'Rental', 'price': '₹2,200', 'rating': 4.7, 'icon': '⛺', 'color': const Color(0xFF11998e)},
        {'name': 'Kheerganga Guest House', 'type': 'Hotel', 'price': '₹1,800', 'rating': 4.2, 'icon': '🌿', 'color': const Color(0xFF2d6a4f)},
      ],
      'jaipur': [
        {'name': 'Heritage Haveli', 'type': 'Hotel', 'price': '₹4,200', 'rating': 4.7, 'icon': '🏰', 'color': const Color(0xFFf7971e)},
        {'name': 'Zostel Jaipur', 'type': 'Hostel', 'price': '₹600', 'rating': 4.4, 'icon': '🎪', 'color': const Color(0xFF6A11CB)},
        {'name': 'Pink City Boutique Inn', 'type': 'Hotel', 'price': '₹3,800', 'rating': 4.5, 'icon': '🌸', 'color': const Color(0xFFED8F03)},
      ],
      'mumbai': [
        {'name': 'Urban Loft Apartment', 'type': 'Rental', 'price': '₹5,800', 'rating': 4.7, 'icon': '💻', 'color': const Color(0xFF4286F4)},
        {'name': 'Backpackers Inn Colaba', 'type': 'Hostel', 'price': '₹950', 'rating': 4.3, 'icon': '🌆', 'color': const Color(0xFF6A11CB)},
        {'name': 'The Taj Mahal Hotel', 'type': 'Hotel', 'price': '₹18,000', 'rating': 4.9, 'icon': '⭐', 'color': const Color(0xFFED8F03)},
      ],
    };

    // Find matching key
    for (final key in stayMap.keys) {
      if (dest.contains(key)) return stayMap[key]!;
    }

    // Generic fallback stays
    return [
      {'name': 'Traveler\'s Hideout', 'type': 'Hostel', 'price': '₹850', 'rating': 4.3, 'icon': '🏕️', 'color': const Color(0xFF6A11CB)},
      {'name': 'The Grand Stay', 'type': 'Hotel', 'price': '₹4,500', 'rating': 4.6, 'icon': '🏨', 'color': const Color(0xFFED8F03)},
      {'name': 'Cozy Retreat Rental', 'type': 'Rental', 'price': '₹3,000', 'rating': 4.5, 'icon': '🏡', 'color': const Color(0xFF134E5E)},
    ];
  }

  Widget _buildStayCard(Map<String, dynamic> stay, int idx) {
    final color = stay['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(stay['icon'] as String, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stay['name'] as String,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stay['type'] as String,
                        style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                    const SizedBox(width: 2),
                    Text(
                      '${stay['rating']}',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: stay['price'] as String,
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    TextSpan(
                      text: ' /night',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          // View button
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening ${stay['name']}... 🏨', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                backgroundColor: color,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Text('View', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms, delay: (300 + idx * 80).ms).slideX(begin: 0.08, end: 0);
  }

  Future<void> _confirmAndSave() async {
    setState(() => _isSaving = true);
    
    // Add the generated itinerary to the request data
    final finalData = {
      ...widget.requestData,
      'generatedItinerary': _itineraryDays,
    };

    final success = await _firebaseService.submitCustomTripRequest(finalData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan Confirmed! Check your inbox soon. ✈️', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm plan. Please try again.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.amber, strokeWidth: 3),
              const SizedBox(height: 24),
              Text(
                'Curating your perfect\n${widget.requestData['style']} trip to ${widget.requestData['destination']}...',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ).animate().fadeIn().shimmer(duration: 2.seconds, color: Colors.amber),
            ],
          ),
        ),
      );
    }

    final budget = widget.requestData['budgetPerPerson'] as int;
    final totalBudget = budget * (widget.requestData['travelersCount'] as int);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text('Your Custom Plan', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.amber[400]!, Colors.amber[600]!]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Destination', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                        Text(widget.requestData['destination'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Style', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                                Text(widget.requestData['style'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Travelers', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                                Text('${widget.requestData['travelersCount']} People', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),

                  // ── Day-by-Day Itinerary ──
                  Text('Day-by-Day Itinerary', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  ..._itineraryDays.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Day\n${index + 1}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.amber[800])),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(day['title'] as String, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(day['description'] as String, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                                const SizedBox(height: 12),
                                ...(day['timeline'] as List<dynamic>).map((item) {
                                  final timelineItem = item as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 65,
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(timelineItem['time'].toString(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[800]), textAlign: TextAlign.center),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(timelineItem['activity'].toString(), style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87))),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (200 + index * 100).ms).slideX(begin: 0.1);
                  }),

                  // ── Nearby Stays ──
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.hotel_rounded, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Text('Nearby Stays', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 4),
                  Text(
                    'Hotels & Hostels near ${widget.requestData['destination']}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 14),
                  ..._getNearbyStays(widget.requestData['destination'] as String)
                      .asMap()
                      .entries
                      .map((entry) => _buildStayCard(entry.value, entry.key)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Bottom Bar ──
          if (!widget.isViewOnly)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estimated Total', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                        Text('₹${NumberFormat('#,##,###').format(totalBudget)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber[700])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _confirmAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2))
                          : Text('Confirm & Book Plan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
