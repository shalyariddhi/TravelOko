import 'package:cloud_firestore/cloud_firestore.dart';

class AITrip {
  final String id;
  final String title;
  final String description;
  final List<Map<String, dynamic>> places; // name, cost, type, lat, lng, address
  final List<List<Map<String, dynamic>>>? days; // Grouped by day
  final List<String>? transport;
  final int budget;
  final int duration;
  final String? userId;

  AITrip({
    required this.id,
    required this.title,
    required this.description,
    required this.places,
    this.days,
    this.transport,
    required this.budget,
    required this.duration,
    this.userId,
  });

  factory AITrip.fromJson(Map<String, dynamic> json, {String id = ''}) {
    List<Map<String, dynamic>> parsedPlaces = [];
    
    // Support parsing from raw strings (initial AI step) or from enriched Maps (Firestore step)
    if (json['places'] != null) {
      for (var p in json['places']) {
        if (p is String) {
          parsedPlaces.add({"name": p, "cost": 0, "type": "activity", "lat": null, "lng": null});
        } else if (p is Map) {
          parsedPlaces.add(Map<String, dynamic>.from(p));
        }
      }
    }

    List<List<Map<String, dynamic>>>? parsedDays;
    if (json['days'] != null) {
      parsedDays = [];
      for (var day in json['days']) {
        if (day is List) {
          parsedDays.add(day.map((e) => Map<String, dynamic>.from(e as Map)).toList());
        }
      }
    }

    List<String>? parsedTransport;
    if (json['transport'] != null) {
      parsedTransport = List<String>.from(json['transport']);
    }

    return AITrip(
      id: id,
      title: json['title'] ?? 'Generated Trip',
      description: json['description'] ?? '',
      places: parsedPlaces,
      days: parsedDays,
      transport: parsedTransport,
      budget: json['budget'] ?? 0,
      duration: json['duration'] ?? 0,
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'places': places,
      'days': days,
      'transport': transport,
      'budget': budget,
      'duration': duration,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
