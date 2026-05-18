import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class MapService {
  static String get apiKey => dotenv.env['GEOAPIFY_API_KEY'] ?? '';
  static String get _orsApiKey => dotenv.env['ORS_API_KEY'] ?? '';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return [];

    // 1. Check Firestore Cache
    final docId = normalizedQuery.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final cacheRef = _firestore.collection('geoapify_cache').doc(docId);
    
    try {
      final snapshot = await cacheRef.get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        return List<Map<String, dynamic>>.from(data['features']);
      }
    } catch (e) {
      // If Firestore read fails (e.g. offline), silently continue to API
      appLogger.e('Firestore cache read error: $e');
    }

    // 2. Not in cache -> Call Geoapify API
    final url =
        "https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(query)}&apiKey=$apiKey&limit=5";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = List<Map<String, dynamic>>.from(data["features"]);

      // 3. Store results in Firestore for next time
      try {
        await cacheRef.set({
          'query': normalizedQuery,
          'features': features,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        appLogger.e('Firestore cache write error: $e');
      }

      return features;
    } else {
      throw Exception("Failed to fetch places");
    }
  }

  static LatLng getLatLng(Map place) {
    final coords = place["geometry"]["coordinates"];
    return LatLng(coords[1], coords[0]);
  }

  static Future<List<Map<String, dynamic>>> getNearbyPlaces({
    required double lat,
    required double lon,
    String category = "catering.restaurant",
    double radius = 2000,
  }) async {
    // Round to 2 decimal places to prevent excessive cache bloat
    final String cacheKey = '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}_${category}_${radius.toInt()}';
    final docId = cacheKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final cacheRef = _firestore.collection('geoapify_nearby_cache').doc(docId);

    try {
      final snapshot = await cacheRef.get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final timestamp = data['timestamp'] as Timestamp?;
        
        // Expire cache after 24 hours
        if (timestamp != null) {
          final age = DateTime.now().difference(timestamp.toDate());
          if (age.inHours < 24) {
            return List<Map<String, dynamic>>.from(data['features']);
          }
        }
      }
    } catch (e) {
      appLogger.e('Firestore nearby cache read error: $e');
    }

    final url =
        "https://api.geoapify.com/v2/places?categories=$category&filter=circle:$lon,$lat,${radius.toInt()}&limit=20&apiKey=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = List<Map<String, dynamic>>.from(data["features"]);

      try {
        await cacheRef.set({
          'cacheKey': cacheKey,
          'features': features,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        appLogger.e('Firestore nearby cache write error: $e');
      }

      return features;
    } else {
      throw Exception("Failed to fetch nearby places");
    }
  }

  static Future<Map<String, dynamic>> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final String cacheKey = "${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}_${end.latitude.toStringAsFixed(4)},${end.longitude.toStringAsFixed(4)}";
    final cacheRef = _firestore.collection('route_cache').doc(cacheKey);

    try {
      final doc = await cacheRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final rawPoints = data['points'] as List;
        return {
          "points": rawPoints.map((p) => LatLng(p['lat'], p['lng'])).toList(),
          "distance": data['distance'],
          "duration": data['duration'],
        };
      }
    } catch (e) {
      appLogger.e('Route cache read error: $e');
    }

    final String orsApiKey = _orsApiKey;

    final url = Uri.parse(
      "https://api.openrouteservice.org/v2/directions/driving-car",
    );

    final response = await http.post(
      url,
      headers: {
        "Authorization": orsApiKey,
        "Content-Type": "application/json",
      },
      body: json.encode({
        "coordinates": [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude]
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final coords = data["features"][0]["geometry"]["coordinates"] as List;
      final distance = data["features"][0]["properties"]["summary"]["distance"];
      final duration = data["features"][0]["properties"]["summary"]["duration"];

      final points = coords.map((c) => LatLng(c[1], c[0])).toList();
      final cacheablePoints = coords.map((c) => {"lat": c[1], "lng": c[0]}).toList();

      try {
        await cacheRef.set({
          "points": cacheablePoints,
          "distance": distance,
          "duration": duration,
          "timestamp": FieldValue.serverTimestamp(),
        });
      } catch (e) {
        appLogger.e('Route cache write error: $e');
      }

      return {
        "points": points,
        "distance": distance,
        "duration": duration,
      };
    } else {
      throw Exception("Route fetch failed: ${response.statusCode}");
    }
  }

  static Future<Map<String, dynamic>?> enrichPlace(String name) async {
    final url = Uri.parse(
      "https://api.geoapify.com/v1/geocode/search?text=$name&apiKey=$apiKey",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        if (data["features"] == null || data["features"].isEmpty) return null;

        final p = data["features"][0];

        return {
          "name": name,
          "lat": p["geometry"]["coordinates"][1],
          "lng": p["geometry"]["coordinates"][0],
          "address": p["properties"]["formatted"] ?? name,
        };
      }
    } catch (e) {
      appLogger.e("Enrichment error: $e");
    }
    return null;
  }
}