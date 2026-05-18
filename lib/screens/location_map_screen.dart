import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/cached_tile_layer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/places_api_service.dart';
import 'accommodations_screen.dart';
import 'category_destinations_screen.dart';
import '../widgets/custom_trip_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class LocationMapScreen extends StatefulWidget {
  final Map<String, dynamic> locationData;
  final bool isOfflineMode;

  const LocationMapScreen({super.key, required this.locationData, this.isOfflineMode = false});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final MapController _mapController = MapController();
  final PlacesApiService _placesApiService = PlacesApiService();

  List<Map<String, dynamic>> _nearbyPlaces = [];
  List<Map<String, dynamic>> _localStays = [];
  List<Map<String, dynamic>> _amenities = [];
  bool _isLoading = true;
  bool _showAtms = true;
  bool _showFuel = true;
  double? _currentLat;
  double? _currentLng;


  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _currentLat = _parseDouble(widget.locationData['lat']);
    _currentLng = _parseDouble(widget.locationData['lng']);
    _loadNearbyData();
  }

  Future<void> _loadNearbyData() async {
    if (widget.isOfflineMode) {
      // Load stored amenities for offline mode
      final storedAmenities = widget.locationData['amenities'];
      if (storedAmenities != null && storedAmenities is List) {
        _amenities = storedAmenities.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      setState(() => _isLoading = false);
      return;
    }
    final rawName = widget.locationData['name'] ?? 'India';
    final locationName = rawName.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');

    if (_currentLat == null || _currentLng == null) {
      final locs = await _placesApiService.fetchLocations(locationName);
      if (locs.isNotEmpty) {
        _currentLat = (locs.first['lat'] as num?)?.toDouble();
        _currentLng = (locs.first['lng'] as num?)?.toDouble();
        if (mounted && _currentLat != null && _currentLng != null) {
          setState(() {});
          try {
            _mapController.move(LatLng(_currentLat!, _currentLng!), 11);
          } catch (_) {}
        }
      }
    }

    final lat = _currentLat ?? 20.5937;
    final lng = _currentLng ?? 78.9629;
    
    final results = await Future.wait([
      _placesApiService.fetchTouristAttractions(lat, lng),
      _placesApiService.fetchAccommodations(locationName, lat, lng),
    ]);

    if (mounted) {
      setState(() {
        _nearbyPlaces = results[0]
            .where((p) => (p['name'] as String).toLowerCase() != locationName.toLowerCase())
            .take(5)
            .toList();
        _localStays = results[1]
            .where((p) => (p['name'] as String).toLowerCase() != locationName.toLowerCase())
            .take(4)
            .toList();
        _isLoading = false;
      });
    }
  }

  LatLng get _destination {
    if (_currentLat != null && _currentLng != null) {
      return LatLng(_currentLat!, _currentLng!);
    }
    final lat = _parseDouble(widget.locationData['lat']);
    final lng = _parseDouble(widget.locationData['lng']);
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
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
          // ── 1. Interactive OpenStreetMap Background ──
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _destination,
                initialZoom: 11,
              ),
              children: [
                cachedTileLayer(),
                // Amenity markers (ATMs & Petrol Pumps)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _destination,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.amber,
                      ),
                    ),
                    ..._amenities
                        .where((a) {
                          final type = a['type'] as String? ?? 'atm';
                          if (type == 'atm' && !_showAtms) return false;
                          if (type == 'fuel' && !_showFuel) return false;
                          return true;
                        })
                        .map((a) {
                          final isAtm = a['type'] == 'atm';
                          return Marker(
                            point: LatLng(
                              (a['lat'] as num).toDouble(),
                              (a['lng'] as num).toDouble(),
                            ),
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(isAtm ? Icons.local_atm : Icons.local_gas_station, color: isAtm ? Colors.green : Colors.orange, size: 28),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(a['name'] ?? (isAtm ? 'ATM' : 'Petrol Pump'),
                                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                            ),
                                          ],
                                        ),
                                        if ((a['brand'] as String?)?.isNotEmpty == true) ...[
                                          const SizedBox(height: 8),
                                          Text(a['brand'], style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14)),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(isAtm ? 'ATM / Cash Point' : 'Fuel Station',
                                            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isAtm ? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: (isAtm ? Colors.green : Colors.orange).withValues(alpha: 0.5), blurRadius: 6),
                                  ],
                                ),
                                child: Icon(
                                  isAtm ? Icons.local_atm : Icons.local_gas_station,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        }),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
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
          
          if (widget.isOfflineMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text('OFFLINE MODE', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),

          // ── Amenity filter chips (shown when amenities are available) ──
          if (_amenities.isNotEmpty)
            Positioned(
              bottom: widget.isOfflineMode ? 24 : MediaQuery.of(context).size.height * 0.42,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterChip('ATMs', Icons.local_atm, Colors.green, _showAtms, (v) => setState(() => _showAtms = v)),
                  const SizedBox(width: 12),
                  _buildFilterChip('Petrol', Icons.local_gas_station, Colors.orange, _showFuel, (v) => setState(() => _showFuel = v)),
                ],
              ),
            ),

          // ── 4. Draggable Bottom Sheet ──
          if (!widget.isOfflineMode)
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

                        // Action Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => CustomTripBottomSheet(initialDestination: locationName),
                                  );
                                },
                                child: Container(
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
                                      Text('Plan Trip',
                                          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ).animate().scaleXY(begin: 0.9, end: 1.0, duration: 500.ms, curve: Curves.easeOutBack),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  // 1. Save metadata to SharedPreferences
                                  final prefs = await SharedPreferences.getInstance();
                                  final existing = prefs.getStringList('saved_maps') ?? [];
                                  final lat = _currentLat ?? widget.locationData['lat'] ?? 20.5937;
                                  final lng = _currentLng ?? widget.locationData['lng'] ?? 78.9629;

                                  // 1b. Fetch nearby ATMs & Petrol Pumps for offline use
                                  final latD = lat is String ? double.parse(lat) : (lat as num).toDouble();
                                  final lngD = lng is String ? double.parse(lng) : (lng as num).toDouble();
                                  final amenities = await _placesApiService.fetchAmenities(latD, lngD);
                                  
                                  final entry = json.encode({
                                    ...widget.locationData,
                                    'lat': lat,
                                    'lng': lng,
                                    'amenities': amenities,
                                    'savedAt': DateTime.now().toIso8601String(),
                                  });
                                  
                                  final name = widget.locationData['name'] ?? '';
                                  existing.removeWhere((e) {
                                    try { return (json.decode(e)['name'] ?? '') == name; } catch(_) { return false; }
                                  });
                                  existing.add(entry);
                                  await prefs.setStringList('saved_maps', existing);

                                  // Update local state so markers appear immediately
                                  if (mounted) {
                                    setState(() => _amenities = amenities);
                                  }
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.blue[700],
                                        content: Row(
                                          children: [
                                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                            const SizedBox(width: 12),
                                            Text('Downloading map for offline zoom...', style: GoogleFonts.poppins(color: Colors.white)),
                                          ],
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }

                                  // 2. Initiate FMTC bulk tile download for offline zoom (approx 20km radius)
                                  try {
                                    final region = CircleRegion(
                                      LatLng(lat is String ? double.parse(lat) : lat.toDouble(), lng is String ? double.parse(lng) : lng.toDouble()),
                                      20.0, // radius in kilometers
                                    );
                                    
                                    final downloadable = region.toDownloadable(
                                      minZoom: 10,
                                      maxZoom: 15,
                                      options: TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.travel.loco',
                                      ),
                                    );

                                    final store = const FMTCStore('osmTiles');
                                    await store.download.startForeground(region: downloadable);
                                    
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: Colors.green[700],
                                          content: Row(
                                            children: [
                                              const Icon(Icons.offline_pin, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Text('"$locationName" saved for offline!',
                                                  style: GoogleFonts.poppins(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Map download failed: $e', style: GoogleFonts.poppins(color: Colors.white)), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[800],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.download_for_offline, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text('Save Map',
                                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ).animate().scaleXY(begin: 0.9, end: 1.0, duration: 500.ms, curve: Curves.easeOutBack),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        if (!widget.isOfflineMode) ...[
                          // ── Places to Visit ──
                          Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Places to Visit', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: () {
                                if (_nearbyPlaces.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryDestinationsScreen(
                                        title: 'Places to Visit',
                                        subtitle: 'Top attractions near $locationName',
                                        locations: _nearbyPlaces.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList(),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text('See All', style: GoogleFonts.poppins(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600)),
                            ),
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
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LocationMapScreen(locationData: place),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 140,
                                        margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.blueGrey[900],
                                        image: (place['image'] != null && (place['image'] as String).isNotEmpty)
                                            ? DecorationImage(
                                                image: NetworkImage(place['image']),
                                                fit: BoxFit.cover,
                                                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.35), BlendMode.darken),
                                                onError: (_, __) {},
                                              )
                                            : null,
                                      ),
                                      alignment: Alignment.bottomLeft,
                                      padding: const EdgeInsets.all(12),
                                      child: Stack(
                                        children: [
                                          if (place['image'] == null || (place['image'] as String).isEmpty)
                                            const Center(child: Icon(Icons.museum_rounded, color: Colors.white24, size: 40)),
                                          Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Text(
                                              place['name'],
                                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(),
                                  );
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
                        ] else ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  Icon(Icons.wifi_off, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                                  const SizedBox(height: 12),
                                  Text("Live places and stays are disabled in Offline Mode.", 
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildFilterChip(
    String label,
    IconData icon,
    Color color,
    bool isActive,
    void Function(bool) onToggle,
  ) {
    return GestureDetector(
      onTap: () => onToggle(!isActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isActive ? color : Colors.white.withValues(alpha: 0.3)),
          boxShadow: isActive
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
