import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/mock_data.dart';

class PlacesApiService {
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/search';
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const Map<String, String> _headers = {
    'User-Agent': 'GoTrivo/1.0',
    'Accept': 'application/json',
  };


  static Future<Map<String, String>> _fetchWikipediaImagesBulk(List<String> placeNames) async {
    if (placeNames.isEmpty) return {};
    try {
      // Wikipedia allows max 50 titles per request
      final titlesToFetch = placeNames.take(50).toList();
      final titles = titlesToFetch.map((e) => Uri.encodeComponent(e)).join('|');
      final url = Uri.parse(
          'https://en.wikipedia.org/w/api.php?action=query&prop=pageimages&format=json&piprop=original&titles=$titles');
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>?;
        
        final Map<String, String> results = {};
        if (pages != null) {
          for (var page in pages.values) {
            final title = page['title'] as String?;
            if (title != null && page.containsKey('original')) {
              results[title] = page['original']['source'] as String;
            }
          }
        }
        return results;
      }
    } catch (_) {}
    return {};
  }

  Future<List<Map<String, dynamic>>> fetchAccommodations([
    String location = 'India',
    double? latitude,
    double? longitude,
  ]) async {
    try {
      dynamic lat = latitude;
      dynamic lon = longitude;

      if (lat == null || lon == null) {
        // 1. Get coordinates for the location using Nominatim
        final geoUrl = Uri.parse(
          '$_nominatimUrl?q=${Uri.encodeComponent(location)}&format=json&limit=1',
        );
        final geoResponse = await http.get(geoUrl, headers: _headers);

        if (geoResponse.statusCode != 200) return [];
        final List geoData = json.decode(geoResponse.body);
        if (geoData.isEmpty) return [];

        lat = geoData[0]['lat'];
        lon = geoData[0]['lon'];
      }

      // 2. Query Overpass API for hotels and hostels around the coordinates
      final query =
          '''
        [out:json];
        (
          node(around:5000,$lat,$lon)["tourism"="hotel"];
          node(around:5000,$lat,$lon)["tourism"="hostel"];
        );
        out 10;
      ''';

      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        final names = elements
            .map((e) => e['tags']?['name'] as String?)
            .where((n) => n != null && n.isNotEmpty)
            .cast<String>()
            .toList();
            
        final wikiImages = await _fetchWikipediaImagesBulk(names);

        final accommodations = elements.map((place) {
          final tags = place['tags'] ?? {};
          final name = tags['name'] ?? 'Local Stay';
          final type = tags['tourism'] == 'hostel' ? 'Hostel' : 'Hotel';

          return {
            'id': place['id'].toString(),
            'name': name,
            'image': wikiImages[name] ?? '',
            'location': location,
            'type': type,
            'price': type == 'Hostel'
                ? 'â‚¹1200'
                : 'â‚¹3500', // Mocked price based on type
            'priceNum': type == 'Hostel' ? 1200 : 3500,
            'rating': 4.5, // Mocked rating
            'reviews': 120, // Mocked reviews count
            'badge': type == 'Hostel' ? 'ðŸŽ’ Backpacker' : 'â­ Standard',
            'amenities': ['Wi-Fi', 'AC', 'Breakfast'],
            'color': const Color(0xFF6A11CB),
          };
        }).toList();

        if (accommodations.isNotEmpty) {
          return accommodations;
        }
      }
    } catch (e) {
      debugPrint('Error fetching accommodations: $e');
    }

    // Fallback to mock data if API fails or returns empty for generic queries like 'India'
    return MockData.accommodations;
  }

  // Fetch tourist attractions using Overpass API
  Future<List<Map<String, dynamic>>> fetchTouristAttractions(
    double lat,
    double lon,
  ) async {
    try {
      final query =
          '''
        [out:json];
        (
          node(around:20000,$lat,$lon)["tourism"="attraction"];
          node(around:20000,$lat,$lon)["tourism"="museum"];
          node(around:20000,$lat,$lon)["tourism"="viewpoint"];
          node(around:20000,$lat,$lon)["historic"="monument"];
        );
        out 30;
      ''';

      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        final validElements = elements.where(
          (place) => place['tags'] != null && place['tags']['name'] != null,
        ).toList();

        final names = validElements
            .map((e) => e['tags']['name'] as String)
            .where((n) => n.isNotEmpty)
            .toList();

        final wikiImages = await _fetchWikipediaImagesBulk(names);

        final attractions = validElements.map((place) {
              final tags = place['tags'];
              final name = tags['name'];

              return {
                'id': place['id'].toString(),
                'name': name,
                'image': wikiImages[name] ?? '',
                'lat': place['lat'],
                'lng': place['lon'],
                'address':
                    tags['addr:full'] ??
                    tags['addr:city'] ??
                    tags['is_in:city'] ??
                    'Local Attraction',
                'rating': 4.5,
                'reviews':
                    150 + (place['id'] % 100)
                        as int, // Mocked realistic looking reviews
              };
            })
            .toList();

        if (attractions.isNotEmpty) {
          return attractions;
        }
      }
    } catch (e) {
      debugPrint('Error fetching attractions: $e');
    }
    return [];
  }

  // Fetch general locations for the home screen / itinerary using Nominatim
  Future<List<Map<String, dynamic>>> fetchLocations(String query) async {
    final url = Uri.parse(
      '$_nominatimUrl?q=${Uri.encodeComponent(query)}&format=json&limit=5',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);

        final names = data
            .map((place) => place['name'] ?? place['display_name']?.split(',')[0] ?? '')
            .where((n) => n.isNotEmpty)
            .cast<String>()
            .toList();

        final wikiImages = await _fetchWikipediaImagesBulk(names);

        return data.map((place) {
          final lat = double.tryParse(place['lat']?.toString() ?? '0.0');
          final lon = double.tryParse(place['lon']?.toString() ?? '0.0');
          final name = place['name'] ?? place['display_name']?.split(',')[0] ?? 'Unknown';

          return {
            'id': place['place_id'].toString(),
            'name': name,
            'address': place['display_name'] ?? '',
            'rating': 4.5, // Mocked for UI
            'reviews': 80, // Mocked
            'types': place['type'] ?? place['class'] ?? 'place',
            'image': wikiImages[name] ?? '',
            'lat': lat,
            'lng': lon,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    }
    return [];
  }

  // Fetch ATMs and Petrol Pumps near a coordinate using Overpass API
  Future<List<Map<String, dynamic>>> fetchAmenities(double lat, double lng) async {
    try {
      final query = '''
        [out:json][timeout:10];
        (
          node(around:20000,$lat,$lng)["amenity"="atm"];
          node(around:20000,$lat,$lng)["amenity"="fuel"];
        );
        out 40;
      ''';

      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
        headers: _headers,
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        return elements.map((e) {
          final tags = e['tags'] ?? {};
          final amenity = tags['amenity'] as String? ?? 'atm';
          return {
            'lat': (e['lat'] as num).toDouble(),
            'lng': (e['lon'] as num).toDouble(),
            'name': tags['name'] ?? (amenity == 'fuel' ? 'Petrol Pump' : 'ATM'),
            'type': amenity, // 'atm' or 'fuel'
            'brand': tags['brand'] ?? tags['operator'] ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching amenities: $e');
    }
    return [];
  }

  // Autocomplete for search bars using Nominatim
  Future<List<String>> fetchAutocomplete(String input) async {
    if (input.isEmpty) return [];

    final url = Uri.parse(
      '$_nominatimUrl?q=${Uri.encodeComponent(input)}&format=json&limit=5&countrycodes=in',
    );
    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<String>((p) => p['display_name']).toList();
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
    }
    return [];
  }
}
