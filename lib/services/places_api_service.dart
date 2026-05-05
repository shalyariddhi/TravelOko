import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlacesApiService {
  // Hardcoding API key for quick integration based on AndroidManifest.xml
  static const String _apiKey = 'AIzaSyAunmmtJVnI36BqnW8piPQFMPH_7h-Mzhw';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Helper to build photo URL
  String _getPhotoUrl(String? photoReference) {
    if (photoReference == null) {
      return 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=500&q=80'; // Fallback
    }
    return '$_baseUrl/photo?maxwidth=800&photo_reference=$photoReference&key=$_apiKey';
  }

  // Fetch hotels/stays
  Future<List<Map<String, dynamic>>> fetchAccommodations([String location = 'India']) async {
    final url = Uri.parse('$_baseUrl/textsearch/json?query=hotels+in+$location&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.map((place) {
          final priceLevel = place['price_level'] ?? 2;
          final rating = (place['rating'] ?? 4.0).toDouble();
          final reviews = place['user_ratings_total'] ?? 100;
          
          int basePrice = 2000;
          if (priceLevel == 1) basePrice = 1500;
          if (priceLevel == 2) basePrice = 3500;
          if (priceLevel == 3) basePrice = 8000;
          if (priceLevel == 4) basePrice = 15000;

          return {
            'id': place['place_id'],
            'name': place['name'],
            'image': _getPhotoUrl(place['photos']?[0]?['photo_reference']),
            'location': place['formatted_address'] ?? 'Unknown Location',
            'type': 'Hotel',
            'price': '₹$basePrice',
            'priceNum': basePrice,
            'rating': rating,
            'reviews': reviews,
            'badge': priceLevel > 2 ? '👑 Premium' : '⭐ Standard',
            'amenities': ['Wi-Fi', 'AC', 'Room Service'],
            'color': const Color(0xFF6A11CB),
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching accommodations: $e');
    }
    return [];
  }

  // Fetch general locations for the home screen / itinerary
  Future<List<Map<String, dynamic>>> fetchLocations(String query) async {
    final url = Uri.parse('$_baseUrl/textsearch/json?query=$query&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((place) {
          final types = (place['types'] as List?)?.take(2).join(', ') ?? '';
          return {
            'id': place['place_id'],
            'name': place['name'],
            'address': place['formatted_address'] ?? place['vicinity'] ?? '',
            'rating': (place['rating'] ?? 0.0).toDouble(),
            'reviews': place['user_ratings_total'] ?? 0,
            'types': types,
            'image': _getPhotoUrl(place['photos']?[0]?['photo_reference']),
            'lat': place['geometry']?['location']?['lat'],
            'lng': place['geometry']?['location']?['lng'],
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    }
    return [];
  }

  // Autocomplete for search bars
  Future<List<String>> fetchAutocomplete(String input) async {
    if (input.isEmpty) return [];
    
    final url = Uri.parse('$_baseUrl/autocomplete/json?input=$input&components=country:in&key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;
        return predictions.map<String>((p) => p['description']).toList();
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
    }
    return [];
  }
}
