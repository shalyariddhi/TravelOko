import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../services/map_service.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart';
import '../services/trip_optimizer.dart';
import '../models/trip.dart';
import '../models/ai_trip.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../utils/cached_tile_layer.dart';

class ExploreItem {
  final String id;
  final String title;
  final double lat;
  final double lng;
  final String type; // "place" or "trip"
  final int? budget;
  final String? image;
  final String? subtitle;
  double distance;

  ExploreItem({
    required this.id,
    required this.title,
    required this.lat,
    required this.lng,
    required this.type,
    this.budget,
    this.image,
    this.subtitle,
    this.distance = 0.0,
  });
}

class ExploreNearbyScreen extends StatefulWidget {
  const ExploreNearbyScreen({super.key});

  @override
  State<ExploreNearbyScreen> createState() => _ExploreNearbyScreenState();
}

class _ExploreNearbyScreenState extends State<ExploreNearbyScreen> {
  final MapController mapController = MapController();
  late final FirebaseService _firebaseService;
  StreamSubscription? _tripSub;
  StreamSubscription? _placeSub;

  List<ExploreItem> allItems = [];
  List<ExploreItem> filteredItems = [];
  List<Trip> liveTrips = [];
  List<Place> livePlaces = [];

  bool isLoading = false;
  bool showList = false;
  bool isGeneratingAI = false;
  bool isBuildingRoute = false;
  AITrip? aiTrip;
  List<LatLng> aiTripRoutePoints = [];
  List<Marker> aiTripMarkers = [];

  String selectedType = "all"; // all | place | trip
  String selectedCategory = "catering.restaurant"; // for fetching new places
  double radius = 2000; // meters
  double maxBudget = 50000;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
    
    // Listen to live trips from Firebase
    _tripSub = _firebaseService.getTrips().listen((trips) {
      if (!mounted) return;
      setState(() {
        liveTrips = trips;
      });
      _mergeAndFilterItems();
    });

    // Listen to community places from Firebase
    _placeSub = _firebaseService.getPlaces().listen((places) {
      if (!mounted) return;
      setState(() {
        livePlaces = places;
      });
      _mergeAndFilterItems();
    });
  }

  @override
  void dispose() {
    _tripSub?.cancel();
    _placeSub?.cancel();
    super.dispose();
  }

  Future<void> loadPlaces() async {
    final center = mapController.camera.center;
    setState(() => isLoading = true);

    try {
      final results = await MapService.getNearbyPlaces(
        lat: center.latitude,
        lon: center.longitude,
        category: selectedCategory,
        radius: radius,
      );

      final List<ExploreItem> fetchedPlaces = results.map((p) {
        final coords = p["geometry"]["coordinates"];
        final props = p["properties"] ?? {};
        
        return ExploreItem(
          id: props["place_id"] ?? UniqueKey().toString(),
          title: props["name"] ?? "Unknown Place",
          lat: coords[1],
          lng: coords[0],
          type: "place",
          subtitle: props["formatted"],
          image: _getImageUrl(p),
        );
      }).toList();

      if (!mounted) return;
      
      // Update global places list
      setState(() {
        // We replace all places entirely on new load to prevent duplicates over time
        allItems.removeWhere((item) => item.type == "place");
        allItems.addAll(fetchedPlaces);
      });
      
      _mergeAndFilterItems();
      setState(() => isLoading = false);
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _mergeAndFilterItems() {
    // 1. Convert Live Trips to ExploreItem
    final tripItems = liveTrips.where((t) => t.lat != null && t.lng != null).map((t) {
      return ExploreItem(
        id: t.id,
        title: t.title,
        lat: t.lat!,
        lng: t.lng!,
        type: "trip",
        budget: t.budget,
        subtitle: "${t.durationDays} days in ${t.destination}",
        image: t.imageUrl.isNotEmpty ? t.imageUrl : null,
      );
    }).toList();

    // 2. Convert Live Community Places to ExploreItem
    final userPlaceItems = livePlaces.map((p) {
      return ExploreItem(
        id: p.id,
        title: p.name,
        lat: p.lat,
        lng: p.lng,
        type: "user_place",
        subtitle: "⭐ ${p.avgRating.toStringAsFixed(1)} (${p.reviewsCount} reviews)",
        image: null, // Could add images later
      );
    }).toList();

    // 3. Clear old trips/places and merge with current API places
    allItems.removeWhere((item) => item.type == "trip" || item.type == "user_place");
    allItems.addAll(tripItems);
    allItems.addAll(userPlaceItems);

    // 3. Apply Filters, Calculate Distance, and Sort
    final center = mapController.camera.center;

    setState(() {
      filteredItems = allItems.where((item) {
        if (selectedType != "all" && item.type != selectedType) return false;
        
        if (item.type == "trip" && item.budget != null && item.budget! > maxBudget) {
          return false;
        }
        
        return true;
      }).toList();

      for (var item in filteredItems) {
        item.distance = calculateDistance(center.latitude, center.longitude, item.lat, item.lng);
      }

      filteredItems.sort((a, b) => a.distance.compareTo(b.distance));
    });
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  String _getImageUrl(Map place) {
    final props = place["properties"] ?? {};
    if (props["datasource"] != null &&
        props["datasource"]["raw"] != null &&
        props["datasource"]["raw"]["photo"] != null) {
      return props["datasource"]["raw"]["photo"];
    }
    final categoryMap = {
      "catering.restaurant": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500&q=80",
      "accommodation.hotel": "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500&q=80",
      "catering.cafe": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500&q=80",
    };
    return categoryMap[selectedCategory] ?? "https://via.placeholder.com/300";
  }

  void _toggleWishlist(ExploreItem item) async {
    await _firebaseService.toggleWishlist(item.id, type: item.type);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Toggled ${item.title} in Wishlist!')));
    }
  }

  Widget buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text("All", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  selected: selectedType == "all",
                  selectedColor: Colors.deepPurple.shade100,
                  onSelected: (val) {
                    if (val) {
                      setState(() => selectedType = "all");
                      _mergeAndFilterItems();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text("Trips", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  selected: selectedType == "trip",
                  selectedColor: Colors.blue.shade100,
                  onSelected: (val) {
                    if (val) {
                      setState(() => selectedType = "trip");
                      _mergeAndFilterItems();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text("Places", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  selected: selectedType == "place",
                  selectedColor: Colors.orange.shade100,
                  onSelected: (val) {
                    if (val) {
                      setState(() => selectedType = "place");
                      _mergeAndFilterItems();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Fetch Controls (Only relevant for places)
          if (selectedType == "all" || selectedType == "place") ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryButton("Restaurants", "catering.restaurant", Icons.restaurant),
                  const SizedBox(width: 8),
                  _buildCategoryButton("Hotels", "accommodation.hotel", Icons.hotel),
                  const SizedBox(width: 8),
                  _buildCategoryButton("Cafes", "catering.cafe", Icons.local_cafe),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text("Search Radius:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: radius,
                    min: 500,
                    max: 5000,
                    divisions: 9,
                    label: "${radius.toInt()}m",
                    activeColor: Colors.orange,
                    onChanged: (val) => setState(() => radius = val),
                    onChangeEnd: (_) => loadPlaces(),
                  ),
                ),
              ],
            ),
          ],
          
          if (selectedType == "all" || selectedType == "trip") ...[
            Row(
              children: [
                Text("Max Budget:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: maxBudget,
                    min: 1000,
                    max: 100000,
                    divisions: 99,
                    label: "₹${maxBudget.toInt()}",
                    activeColor: Colors.blue,
                    onChanged: (val) => setState(() {
                      maxBudget = val;
                      _mergeAndFilterItems();
                    }),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, String category, IconData icon) {
    final isSelected = selectedCategory == category;
    
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.orange : Colors.grey[100],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
        shape: const StadiumBorder(),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
      onPressed: () {
        setState(() => selectedCategory = category);
        loadPlaces();
      },
    );
  }

  void showDetails(ExploreItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (item.type == "trip" ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.type == "trip" ? Icons.flight_takeoff : Icons.place, color: item.type == "trip" ? Colors.blue : Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(item.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(item.subtitle ?? "", style: GoogleFonts.poppins(color: Colors.grey[700])),
              if (item.type == "trip" && item.budget != null) ...[
                const SizedBox(height: 8),
                Text("Budget: ₹${item.budget}", style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
              if (item.type == "user_place") ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Community Reviews", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text("Write Review"),
                      onPressed: () {
                        Navigator.pop(context);
                        _showReviewModal(item.id, item.title);
                      },
                    )
                  ],
                ),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: StreamBuilder<List<Review>>(
                    stream: _firebaseService.getReviews(item.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final reviews = snapshot.data!;
                      if (reviews.isEmpty) return const Center(child: Text("No reviews yet. Be the first!"));

                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final r = reviews[index];
                          return FutureBuilder<int>(
                            future: _firebaseService.getUserTrustScore(r.userId),
                            builder: (context, trustSnap) {
                              final trustScore = trustSnap.data ?? 0;
                              final isVerified = trustScore > 70;
                              return GestureDetector(
                                onLongPress: () => _showReportModal(r.userId, item.id),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      Text(r.userName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                                      if (isVerified) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: Colors.blue, size: 14),
                                      ],
                                      const Spacer(),
                                      Row(children: List.generate(r.rating, (i) => const Icon(Icons.star, color: Colors.orange, size: 14))),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.comment, style: GoogleFonts.poppins(fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text("Hold to report", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.type == "trip" ? Colors.blue : (item.type == "user_place" ? Colors.green : Colors.orange), 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showAddPlaceModal(LatLng point) {
    final TextEditingController nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Custom Place", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Place Name"),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    final place = Place(id: '', name: nameController.text.trim(), lat: point.latitude, lng: point.longitude);
                    await _firebaseService.addPlace(place);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place Added!')));
                  },
                  child: Text("Create Place", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showReviewModal(String placeId, String placeName) {
    final TextEditingController commentController = TextEditingController();
    double currentRating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Review $placeName", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text("Rating", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Slider(
                    value: currentRating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: currentRating.toInt().toString(),
                    activeColor: Colors.orange,
                    onChanged: (val) => setModalState(() => currentRating = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: "Write your review..."),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (commentController.text.trim().isEmpty) return;
                        Navigator.pop(context);
                        await _firebaseService.addReview(placeId, currentRating.toInt(), commentController.text.trim());
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Submitted!')));
                      },
                      child: Text("Submit Review", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showReportModal(String contentId, String placeId) {
    final reasons = [
      "Spam or fake content",
      "Inappropriate or offensive",
      "Wrong location",
      "Dangerous misinformation",
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_outlined, color: Colors.red),
                  const SizedBox(width: 8),
                  Text("Report Content", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text("Why are you reporting this?", style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 16),
              ...reasons.map((reason) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.report_problem_outlined, color: Colors.orange),
                title: Text(reason, style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () async {
                  Navigator.pop(context);
                  await _firebaseService.reportContent(
                    contentId: placeId,
                    type: 'place',
                    reason: reason,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Report submitted. Thank you!")),
                    );
                  }
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _showAITripModal() {
    final TextEditingController budgetController = TextEditingController(text: maxBudget.toInt().toString());
    final TextEditingController daysController = TextEditingController(text: "3");
    final TextEditingController prefController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 28),
                  const SizedBox(width: 12),
                  Text("AI Planner", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Text("Budget (₹)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "e.g. 15000"),
              ),
              const SizedBox(height: 12),
              Text("Days", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "e.g. 3"),
              ),
              const SizedBox(height: 12),
              Text("Preferences", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              TextField(
                controller: prefController,
                decoration: const InputDecoration(hintText: "e.g. loves cafes, mountains"),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _generateTrip(
                      int.tryParse(budgetController.text) ?? 10000,
                      int.tryParse(daysController.text) ?? 3,
                      prefController.text,
                    );
                  },
                  child: Text("Generate Magic Itinerary", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateTrip(int budget, int days, String prefs) async {
    setState(() {
      isGeneratingAI = true;
      aiTrip = null;
      aiTripRoutePoints = [];
      aiTripMarkers = [];
    });

    try {
      final contextPlaces = filteredItems.take(10).map((e) => "${e.title} (${e.type})").toList();
      final locString = "${mapController.camera.center.latitude.toStringAsFixed(2)}, ${mapController.camera.center.longitude.toStringAsFixed(2)}";

      final result = await AIService.getTripSuggestion(
        location: locString,
        budget: budget,
        days: days,
        nearbyContext: contextPlaces,
        preferences: prefs,
      );

      // Step 1: Parse raw AI result
      final rawTrip = AITrip.fromJson(result);

      // Step 2: Enrich each place name → real lat/lng via Geoapify
      final List<Map<String, dynamic>> enrichedPlaces = [];
      for (final p in rawTrip.places) {
        final name = p['name'] ?? p.toString();
        final enriched = await MapService.enrichPlace(name);
        if (enriched != null) {
          // Merge AI cost and type with enriched lat/lng
          enrichedPlaces.add({
            ...p,
            'lat': enriched['lat'],
            'lng': enriched['lng'],
            'address': enriched['address'],
          });
        } else {
          enrichedPlaces.add({...p, 'lat': null, 'lng': null});
        }
      }

      // Step 3: Run the Smart Trip Optimizer
      final optimizedData = TripOptimizer.buildSmartTrip(
        enrichedPlaces,
        rawTrip.duration,
        rawTrip.budget,
      );

      final budgetedDays = (optimizedData['days'] as List).cast<List<Map<String, dynamic>>>();
      final transport = (optimizedData['transport'] as List).cast<String>();
      final flatPlaces = (optimizedData['flatPlaces'] as List).cast<Map<String, dynamic>>();

      // Step 4: Build final enriched AITrip object
      final enrichedTrip = AITrip(
        id: '',
        title: rawTrip.title,
        description: rawTrip.description,
        places: flatPlaces, // Only the places that survived the budget filter
        days: budgetedDays,
        transport: transport,
        budget: rawTrip.budget,
        duration: rawTrip.duration,
      );

      // Step 4: Save to Firebase
      await _firebaseService.saveAITrip(enrichedTrip);

      if (mounted) {
        setState(() {
          aiTrip = enrichedTrip;
          isGeneratingAI = false;
          showList = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isGeneratingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI Failed: $e")));
      }
    }
  }

  Future<void> _showAITripOnMap() async {
    if (aiTrip == null) return;
    final validPlaces = aiTrip!.places.where((p) => p['lat'] != null && p['lng'] != null).toList();
    if (validPlaces.length < 2) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough places with coordinates to route.")));
      return;
    }

    setState(() => isBuildingRoute = true);

    try {
      final points = validPlaces.map((p) => LatLng(p['lat'], p['lng'])).toList();
      List<LatLng> fullRoute = [];

      for (int i = 0; i < points.length - 1; i++) {
        final segment = await MapService.getRoute(start: points[i], end: points[i + 1]);
        fullRoute.addAll(segment["points"] as List<LatLng>);
      }

      final markers = validPlaces.asMap().entries.map((entry) {
        final idx = entry.key;
        final p = entry.value;
        return Marker(
          point: LatLng(p['lat'], p['lng']),
          width: 40,
          height: 40,
          child: CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: Text("${idx + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        );
      }).toList();

      if (mounted) {
        setState(() {
          aiTripRoutePoints = fullRoute;
          aiTripMarkers = markers;
          isBuildingRoute = false;
          showList = false; // switch to map view
        });
        // pan map to first point
        mapController.move(points.first, 11);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isBuildingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Route error: $e")));
      }
    }
  }

  Widget buildAITripCard() {
    if (isGeneratingAI) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.shade200),
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text("✨ AI is crafting & enriching your trip...", style: GoogleFonts.poppins(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Geocoding places & saving to your profile", style: GoogleFonts.poppins(color: Colors.deepPurple.shade300, fontSize: 12)),
          ],
        ),
      );
    }

    if (aiTrip == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade500]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(child: Text(aiTrip!.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
              IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => setState(() {
                aiTrip = null;
                aiTripRoutePoints = [];
                aiTripMarkers = [];
              })),
            ],
          ),
          const SizedBox(height: 8),
          Text(aiTrip!.description, style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Itinerary Breakdown:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 8),
                if (aiTrip!.days != null && aiTrip!.days!.isNotEmpty)
                  ...aiTrip!.days!.asMap().entries.map((dayEntry) {
                    final dayIdx = dayEntry.key;
                    final dayPlaces = dayEntry.value;
                    if (dayPlaces.isEmpty) return const SizedBox.shrink();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Text("Day ${dayIdx + 1}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        ...dayPlaces.map((p) {
                          final name = p['name'] ?? p.toString();
                          final cost = p['cost'] ?? 0;
                          final hasCoords = p['lat'] != null && p['lng'] != null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(hasCoords ? Icons.location_on : Icons.location_off, size: 14, color: hasCoords ? Colors.amber : Colors.white30),
                                const SizedBox(width: 8),
                                Expanded(child: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                                if (cost > 0)
                                  Text("₹$cost", style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12)),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  })
                else
                  ...aiTrip!.places.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    final name = p['name'] ?? p.toString();
                    final hasCoords = p['lat'] != null && p['lng'] != null;
                    final address = p['address'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: hasCoords ? Colors.amber : Colors.white30,
                            child: Text("${idx + 1}", style: const TextStyle(color: Colors.deepPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              if (address != null)
                                Text(address, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
                              if (!hasCoords)
                                Text("⚠ Could not geocode", style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 11)),
                            ],
                          )),
                        ],
                      ),
                    );
                  }),
                  
                if (aiTrip!.transport != null && aiTrip!.transport!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text("Transport Plan:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(aiTrip!.transport!.length, (i) {
                      final mode = aiTrip!.transport![i];
                      IconData icon = Icons.directions_walk;
                      if (mode == 'car') icon = Icons.directions_car;
                      else if (mode == 'bus/train') icon = Icons.directions_transit;
                      else if (mode == 'flight') icon = Icons.flight;
                      
                      return Chip(
                        avatar: Icon(icon, size: 14, color: Colors.white),
                        label: Text(mode.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, color: Colors.white)),
                        backgroundColor: Colors.deepPurple.shade400,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }),
                  )
                ]
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("₹${aiTrip!.budget}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              Text("${aiTrip!.duration} days", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: isBuildingRoute ? null : _showAITripOnMap,
              icon: isBuildingRoute
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple))
                  : const Icon(Icons.route),
              label: Text(
                isBuildingRoute ? "Building Route..." : "Show Route on Map",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final trip = aiTrip;
                if (trip == null) return;
                try {
                  await _firebaseService.shareAITrip(trip);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Trip shared to the public feed! 🎉',
                            style: GoogleFonts.poppins()),
                        backgroundColor: Colors.deepPurple,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error sharing: $e')));
                  }
                }
              },
              icon: const Icon(Icons.share, size: 18),
              label: Text('Share to Feed',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Explore Unified", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(showList ? Icons.map_outlined : Icons.format_list_bulleted, color: Colors.deepPurple),
            onPressed: () {
              setState(() {
                showList = !showList;
              });
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome),
        label: Text("AI Trip", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        onPressed: _showAITripModal,
      ),
      body: Column(
        children: [
          buildFilters(),
          Expanded(
            child: Stack(
              children: [
                if (!showList)
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(28.6139, 77.2090),
                      initialZoom: 13,
                      onLongPress: (tapPosition, point) => _showAddPlaceModal(point),
                    ),
                    children: [
                      cachedTileLayer(),
                      MarkerClusterLayerWidget(
                        options: MarkerClusterLayerOptions(
                          maxClusterRadius: 45,
                          size: const Size(40, 40),
                          markers: filteredItems.map((item) {
                            final isTrip = item.type == "trip";
                            final isUserPlace = item.type == "user_place";
                            final color = isTrip ? Colors.blue : (isUserPlace ? Colors.green : Colors.orange);
                            final icon = isTrip ? Icons.flight_takeoff : (isUserPlace ? Icons.star : Icons.place);
                            return Marker(
                              point: LatLng(item.lat, item.lng),
                              width: 60,
                              height: 60,
                              child: GestureDetector(
                                onTap: () => showDetails(item),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                                  ),
                                  child: Icon(icon, color: Colors.white, size: 24),
                                ),
                              ),
                            );
                          }).toList(),
                          builder: (context, markers) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                              ),
                              child: Center(
                                child: Text(
                                  markers.length.toString(),
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // AI Trip Route Overlay
                      if (aiTripRoutePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: aiTripRoutePoints,
                              strokeWidth: 5,
                              color: Colors.deepPurple,
                              borderStrokeWidth: 2,
                              borderColor: Colors.white,
                            ),
                          ],
                        ),
                      // AI Trip numbered stop markers
                      if (aiTripMarkers.isNotEmpty)
                        MarkerLayer(markers: aiTripMarkers),
                    ],
                  )
                else
                  Column(
                    children: [
                      buildAITripCard(),
                      Expanded(
                        child: filteredItems.isEmpty 
                          ? Center(child: Text("No items found.", style: GoogleFonts.poppins(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isTrip = item.type == "trip";

                          return GestureDetector(
                            onTap: () {
                              mapController.move(LatLng(item.lat, item.lng), 15);
                              setState(() => showList = false);
                              showDetails(item);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // IMAGE
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Image.network(
                                      item.image ?? "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=500&q=80",
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 150,
                                        width: double.infinity,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
                                      ),
                                    ),
                                  ),
                                  // DETAILS
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    title: Text(item.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(item.subtitle ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: (isTrip ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(isTrip ? "TRIP" : "PLACE", style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: isTrip ? Colors.blue : Colors.orange)),
                                            ),
                                            if (item.budget != null) ...[
                                              const SizedBox(width: 8),
                                              Text("₹${item.budget}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue)),
                                            ],
                                            const SizedBox(width: 12),
                                            Icon(Icons.directions_walk, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text("${item.distance.toStringAsFixed(1)} km", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                                          ],
                                        )
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.favorite_border),
                                      color: Colors.red,
                                      onPressed: () => _toggleWishlist(item),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      ), // Close Expanded
                    ],
                  ),

                if (isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
