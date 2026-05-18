import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/map_service.dart';
import '../services/firebase_service.dart';
import '../models/trip.dart';
import '../utils/cached_tile_layer.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  LatLng _currentCenter = const LatLng(28.6139, 77.2090); // Delhi Default
  Marker? _selectedMarker;
  List<Marker> _placeMarkers = [];
  bool _isFetchingPlaces = false;
  late final FirebaseService _firebaseService;

  // Routing State
  LatLng? _startPoint;
  LatLng? _endPoint;
  List<LatLng> _routePoints = [];
  double? _routeDistance;
  double? _routeDuration;

  @override
  void initState() {
    super.initState();
    _firebaseService = FirebaseService();
  }

  Future<void> _loadNearbyPlaces(String type) async {
    final center = _mapController.camera.center;
    setState(() => _isFetchingPlaces = true);

    try {
      final results = await MapService.getNearbyPlaces(
        lat: center.latitude,
        lon: center.longitude,
        category: type,
      );

      final isRestaurant = type == "catering.restaurant";

      final markers = results.map((place) {
        final coords = place["geometry"]["coordinates"];
        final props = place["properties"] ?? {};
        final name = props["name"] ?? (isRestaurant ? "Restaurant" : "Hotel");

        return Marker(
          point: LatLng(coords[1], coords[0]),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (_) => Container(
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
                              color: (isRestaurant ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isRestaurant ? Icons.restaurant : Icons.hotel, color: isRestaurant ? Colors.orange : Colors.blue, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(props["formatted"] ?? "No address available", style: GoogleFonts.poppins(color: Colors.grey[700])),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: isRestaurant ? Colors.orange : Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () => Navigator.pop(context),
                          child: Text("Close", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: isRestaurant ? Colors.orange : Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
              ),
              child: Icon(isRestaurant ? Icons.restaurant : Icons.hotel, color: Colors.white, size: 20),
            ),
          ),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _placeMarkers = markers;
          _isFetchingPlaces = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingPlaces = false);
    }
  }

  void _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await MapService.searchPlaces(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching places: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onPlaceSelected(Map<String, dynamic> place) {
    final latLng = MapService.getLatLng(place);
    final properties = place['properties'] ?? {};
    
    setState(() {
      _currentCenter = latLng;
      _searchResults = [];
      _searchController.text = properties['formatted'] ?? _searchController.text;
      
      _selectedMarker = Marker(
        point: latLng,
        width: 60,
        height: 60,
        child: const Icon(Icons.location_on, size: 40, color: Colors.redAccent),
      );

      // UX Upgrade: searching sets the destination automatically!
      _endPoint = latLng;
      if (_startPoint != null) {
        _fetchRoute();
      }
    });

    // Move the map smoothly to the selected location
    _mapController.move(latLng, 14);
    FocusScope.of(context).unfocus(); // Dismiss keyboard
  }

  Future<void> _fetchRoute() async {
    if (_startPoint == null || _endPoint == null) return;
    try {
      final result = await MapService.getRoute(
        start: _startPoint!,
        end: _endPoint!,
      );
      setState(() {
        _routePoints = result["points"];
        _routeDistance = result["distance"] / 1000; // km
        _routeDuration = result["duration"] / 60; // minutes
      });
    } catch (e) {
      debugPrint("Route error: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 13,
              onTap: (tapPosition, latlng) {
                setState(() {
                  if (_startPoint == null) {
                    _startPoint = latlng;
                  } else if (_endPoint == null) {
                    _endPoint = latlng;
                    _fetchRoute();
                  } else {
                    _startPoint = latlng;
                    _endPoint = null;
                    _routePoints = [];
                    _routeDistance = null;
                    _routeDuration = null;
                  }
                });
              },
            ),
            children: [
              cachedTileLayer(),
              
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              
              // Live Trips Stream
              StreamBuilder<List<Trip>>(
                stream: _firebaseService.getTrips(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final trips = snapshot.data!;
                  final tripMarkers = trips.where((t) => t.lat != null && t.lng != null).map((trip) {
                    return Marker(
                      point: LatLng(trip.lat!, trip.lng!),
                      width: 80,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _showTripDetails(trip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '₹${trip.budget}',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  }).toList();

                  return MarkerLayer(markers: tripMarkers);
                },
              ),

              // Search & Nearby Places Markers
              MarkerLayer(
                markers: [
                  if (_selectedMarker != null) _selectedMarker!,
                  ..._placeMarkers,
                ],
              ),
              
              // Routing A/B Markers
              MarkerLayer(
                markers: [
                  if (_startPoint != null)
                    Marker(
                      point: _startPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.circle, color: Colors.green, size: 24),
                    ),
                  if (_endPoint != null && _selectedMarker == null)
                    Marker(
                      point: _endPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                    ),
                ],
              ),
            ],
          ),
          
          // 2. Floating Search Bar & Results
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _searchPlaces(),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Search destinations...",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                        suffixIcon: _isLoading 
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16, 
                                  height: 16, 
                                  child: CircularProgressIndicator(strokeWidth: 2)
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                  
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          final props = place['properties'] ?? {};
                          final title = props['city'] ?? props['name'] ?? props['formatted']?.split(',').first ?? 'Unknown';
                          final subtitleElements = [props['state'], props['country']].where((e) => e != null && e.toString().isNotEmpty).toList();
                          final subtitle = subtitleElements.isNotEmpty ? subtitleElements.join(', ') : props['formatted'] ?? '';
                          
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                            ),
                            title: Text(
                              title, 
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: subtitle.isNotEmpty ? Text(
                              subtitle,
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ) : null,
                            onTap: () => _onPlaceSelected(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 3. Back Button
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: FloatingActionButton.small(
              heroTag: 'mapBack',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
          
          // 4. Loading Overlay for POIs
          if (_isFetchingPlaces)
            const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),
            
          // 4. Floating Nearby Filters
          Positioned(
            bottom: _routeDistance != null ? 100 : 20, // Adjust position if route info is showing
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, 
                        foregroundColor: Colors.white, 
                        shape: const StadiumBorder(),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.restaurant, size: 18),
                      label: Text("Restaurants", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      onPressed: () => _loadNearbyPlaces("catering.restaurant"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, 
                        foregroundColor: Colors.white, 
                        shape: const StadiumBorder(),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.hotel, size: 18),
                      label: Text("Hotels", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      onPressed: () => _loadNearbyPlaces("accommodation.hotel"),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Route Info Panel
          if (_routeDistance != null && _routeDuration != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Distance", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                        Text("${_routeDistance!.toStringAsFixed(1)} km", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Est. Time", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                        Text("${_routeDuration!.toStringAsFixed(0)} mins", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _startPoint = null;
                          _endPoint = null;
                          _routePoints = [];
                          _routeDistance = null;
                          _routeDuration = null;
                          _selectedMarker = null; // Clear selected place too
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTripDetails(Trip trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: NetworkImage(trip.imageUrl.isNotEmpty ? trip.imageUrl : 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=500&q=80'), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(trip.destination, style: GoogleFonts.poppins(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTripInfo(Icons.account_balance_wallet, 'Budget', '₹${trip.budget}'),
                _buildTripInfo(Icons.calendar_month, 'Duration', '${trip.durationDays} Days'),
                _buildTripInfo(Icons.group, 'Spots', '${trip.seatsLeft}/${trip.totalSeats}'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(context);
                  // In a real app, you would navigate to the full trip detail screen here
                },
                child: Text("Close", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple, size: 20),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500])),
        Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}