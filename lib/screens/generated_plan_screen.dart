import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/places_api_service.dart';

class GeneratedPlanScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final bool isViewOnly;

  const GeneratedPlanScreen({super.key, required this.requestData, this.isViewOnly = false});

  @override
  State<GeneratedPlanScreen> createState() => _GeneratedPlanScreenState();
}

class _GeneratedPlanScreenState extends State<GeneratedPlanScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PlacesApiService _placesApiService = PlacesApiService();
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

  Future<void> _generateMockItinerary() async {
    final destination = widget.requestData['destination'] as String;
    final days = widget.requestData['days'] as int;
    final style = widget.requestData['style'] as String;
    final budget = widget.requestData['budgetPerPerson'] as int;
    final travelers = widget.requestData['travelersCount'] as int;

    // Fetch real places - run 2 queries in parallel for more variety
    final results = await Future.wait([
      _placesApiService.fetchLocations(
        style == 'Adventure' ? 'adventure trekking waterfalls $destination'
        : style == 'Cultural' ? 'temples forts heritage museums $destination'
        : style == 'Party' ? 'nightlife bars clubs $destination'
        : 'gardens viewpoints scenic spots $destination'),
      _placesApiService.fetchLocations(
        style == 'Adventure' ? 'camping outdoor activities $destination'
        : style == 'Cultural' ? 'ancient ruins palaces monuments $destination'
        : style == 'Party' ? 'beach clubs restaurants rooftop $destination'
        : 'cafes waterfalls resorts $destination'),
    ]);

    // Merge & shuffle for maximum variety each time
    final allPlaces = [...results[0], ...results[1]];
    allPlaces.shuffle();

    // Style-specific lunch options (rotate each day)
    final lunchOptions = {
      'Adventure': ['🥾 Quick energy lunch at a mountain café', '🍱 Packed trail lunch with a view', '🥗 Healthy fuel-up at a local dhaba'],
      'Cultural': ['🍛 Traditional thali at a heritage restaurant', '🫓 Street food tour through the old bazaar', '☕ Chai & snacks at a rooftop café'],
      'Party': ['🍹 Brunch at a beach shack', '🍔 Late lunch at a rooftop bar', '🥂 Pre-party food crawl'],
      'Relaxing': ['🥗 Healthy lunch by the pool/lake', '🫖 Peaceful meal at a boutique café', '🍜 Leisurely lunch at a scenic restaurant'],
    };

    // Style-specific evening options (rotate each day)
    final eveningOptions = {
      'Adventure': ['🏕️ Bonfire & camp dinner under the stars', '🌄 Sunset hike with packed dinner', '🔥 Riverside campfire & stargazing'],
      'Cultural': ['🎭 Evening cultural show or heritage walk', '🪔 Temple aarti ceremony experience', '🎨 Local craft workshop & dinner'],
      'Party': ['🎉 Club hopping through the nightlife strip', '🎵 Live music evening at a rooftop bar', '🍸 Sunset cocktail cruise or beach party'],
      'Relaxing': ['🌇 Sunset watching at a scenic viewpoint', '🛁 Evening spa & wellness session', '🌙 Candlelit dinner by the waterfront'],
    };

    // Morning activity prefixes vary by day
    final morningVerbs = ['Visit', 'Explore', 'Discover', 'Head to', 'Check out', 'Wander through'];
    final afternoonVerbs = ['Spend time at', 'Continue to', 'Make your way to', 'Stop by', 'Immerse yourself in'];

    final lunchList = lunchOptions[style]!;
    final eveningList = eveningOptions[style]!;
    final morningTime = style == 'Party' ? '10:30 AM' : '08:30 AM';
    final afternoonTime = style == 'Party' ? '02:30 PM' : '01:30 PM';
    final eveningTime = style == 'Party' ? '10:00 PM' : '06:00 PM';
    final budgetLabel = budget > 8000 ? '💎 Premium' : budget > 3000 ? '⭐ Comfort' : '🎒 Budget';

    _itineraryDays = List.generate(days, (index) {
      if (index == 0) {
        final firstPlace = allPlaces.isNotEmpty ? allPlaces[0] : null;
        return {
          'title': 'Arrival & First Impressions',
          'description': 'Welcome to $destination! $budgetLabel stay for $travelers traveler${travelers > 1 ? "s" : ""}. Get settled and soak it all in.',
          'timeline': [
            {'time': '12:00 PM', 'activity': '✈️ Arrive & transfer to accommodation'},
            {'time': '02:00 PM', 'activity': '🏨 Check-in & freshen up'},
            if (firstPlace != null)
              {'time': '04:30 PM', 'activity': '📍 First stop: ${firstPlace['name']}'}
            else
              {'time': '04:30 PM', 'activity': '🚶 Evening walk around the neighbourhood'},
            {'time': '07:30 PM', 'activity': '🍽️ Welcome dinner — try the local specialty'},
          ]
        };
      } else if (index == days - 1) {
        final lastPlace = allPlaces.length > 1 ? allPlaces[allPlaces.length - 1] : null;
        return {
          'title': 'Last Day & Departure',
          'description': 'Soak in $destination one last time before heading home. Safe travels! ✈️',
          'timeline': [
            {'time': '08:00 AM', 'activity': '☕ Relaxed breakfast & pack up'},
            if (lastPlace != null)
              {'time': '10:00 AM', 'activity': '🛍️ Final visit to ${lastPlace['name']}'}
            else
              {'time': '10:00 AM', 'activity': '🛍️ Last-minute shopping for souvenirs'},
            {'time': '12:30 PM', 'activity': '🥘 Farewell lunch at a favourite spot'},
            {'time': '03:00 PM', 'activity': '🚕 Transfer to airport / railway station'},
          ]
        };
      } else {
        // Unique places per day — offset by day index, no repetition
        final offset = (index - 1) * 3;
        final p1 = allPlaces.isNotEmpty ? allPlaces[offset % allPlaces.length] : null;
        final p2 = allPlaces.length > 1 ? allPlaces[(offset + 1) % allPlaces.length] : null;
        final p3 = allPlaces.length > 2 ? allPlaces[(offset + 2) % allPlaces.length] : null;

        final morningVerb = morningVerbs[index % morningVerbs.length];
        final afternoonVerb = afternoonVerbs[index % afternoonVerbs.length];
        final lunch = lunchList[index % lunchList.length];
        final evening = eveningList[index % eveningList.length];

        final dayTitles = {
          'Adventure': ['Mountain & Trails Day', 'Wild Exploration Day', 'Adrenaline Rush Day', 'Nature Discovery Day'],
          'Cultural': ['Heritage Deep Dive', 'History & Arts Day', 'Temples & Traditions Day', 'Old City Exploration'],
          'Party': ['Beach Vibes Day', 'Night Owl Day', 'Sunset & Sundown Day', 'Festival Mode Day'],
          'Relaxing': ['Slow Morning Day', 'Nature & Serenity Day', 'Spa & Scenic Day', 'Peaceful Wandering Day'],
        };
        final titleList = dayTitles[style]!;
        final dayTitle = 'Day ${index + 1} — ${titleList[(index - 1) % titleList.length]}';

        return {
          'title': dayTitle,
          'description': p1 != null
              ? 'Today\'s highlights: ${[p1, p2, p3].where((p) => p != null).map((p) => p!['name']).join(', ')}.'
              : 'A full day of $style experiences in $destination.',
          'timeline': [
            {
              'time': morningTime,
              'activity': p1 != null ? '🌅 $morningVerb ${p1['name']}' : '🌅 Morning exploration of $destination',
              if (p1 != null) 'address': p1['address'] ?? '',
              if (p1 != null) 'rating': p1['rating'],
              if (p1 != null) 'reviews': p1['reviews'],
            },
            {'time': '11:00 AM', 'activity': lunch},
            {
              'time': afternoonTime,
              'activity': p2 != null ? '🗺️ $afternoonVerb ${p2['name']}' : '🗺️ Afternoon discovery in $destination',
              if (p2 != null) 'address': p2['address'] ?? '',
              if (p2 != null) 'rating': p2['rating'],
              if (p2 != null) 'reviews': p2['reviews'],
            },
            if (p3 != null) {
              'time': '04:00 PM',
              'activity': '📸 Quick stop: ${p3['name']}',
              'address': p3['address'] ?? '',
              'rating': p3['rating'],
              'reviews': p3['reviews'],
            },
            {'time': eveningTime, 'activity': evening},
          ],
        };
      }
    });

    if (mounted) setState(() => _isGenerating = false);
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
                                  final hasPlace = timelineItem.containsKey('address') && (timelineItem['address'] as String).isNotEmpty;
                                  final rating = timelineItem['rating'];
                                  final reviews = timelineItem['reviews'];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Time badge
                                        Container(
                                          width: 65,
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[50],
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.amber[200]!),
                                          ),
                                          child: Text(timelineItem['time'].toString(),
                                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                                              textAlign: TextAlign.center),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Activity name
                                              Text(timelineItem['activity'].toString(),
                                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                              // Address row
                                              if (hasPlace) ...[
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                                                    const SizedBox(width: 3),
                                                    Expanded(
                                                      child: Text(
                                                        timelineItem['address'].toString(),
                                                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              // Rating
                                              if (hasPlace && rating != null && (rating as double) > 0) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    ...List.generate(5, (i) => Icon(
                                                      i < (rating as double).round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                                      size: 12,
                                                      color: Colors.amber[600],
                                                    )),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${rating.toStringAsFixed(1)}${reviews != null && (reviews as int) > 0 ? " (${reviews})" : ""}',
                                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
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
