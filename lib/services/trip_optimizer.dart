import 'dart:math' as math;

class TripOptimizer {
  static double calculateDistance(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a['lat'] == null || a['lng'] == null || b['lat'] == null || b['lng'] == null) {
      return 0.0;
    }
    // Haversine formula
    const R = 6371; // km
    final dLat = _toRadians(b['lat'] - a['lat']);
    final dLon = _toRadians(b['lng'] - a['lng']);
    final lat1 = _toRadians(a['lat']);
    final lat2 = _toRadians(b['lat']);

    final haversine = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return R * c;
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  static String chooseTransport(double distanceKm) {
    if (distanceKm == 0) return "walk"; // missing coords
    if (distanceKm < 2) return "walk";
    if (distanceKm < 50) return "car";
    if (distanceKm < 300) return "bus/train";
    return "flight";
  }

  static List<Map<String, dynamic>> optimizeBudget(List<Map<String, dynamic>> places, int maxBudget) {
    int total = 0;
    List<Map<String, dynamic>> selected = [];

    // Sort by cost (cheapest first)
    final sortedPlaces = List<Map<String, dynamic>>.from(places);
    sortedPlaces.sort((a, b) {
      final costA = (a['cost'] ?? 0) is num ? (a['cost'] ?? 0) : int.tryParse(a['cost'].toString()) ?? 0;
      final costB = (b['cost'] ?? 0) is num ? (b['cost'] ?? 0) : int.tryParse(b['cost'].toString()) ?? 0;
      return costA.compareTo(costB);
    });

    for (var p in sortedPlaces) {
      final rawCost = (p['cost'] ?? 0) is num ? (p['cost'] ?? 0) : int.tryParse(p['cost'].toString()) ?? 0;
      final cost = (rawCost as num).toInt();
      if (total + cost <= maxBudget || maxBudget == 0) {
        selected.add(p);
        total += cost;
      }
    }

    // If budget stripped all places, return the cheapest one so the day isn't completely empty
    if (selected.isEmpty && sortedPlaces.isNotEmpty) {
      selected.add(sortedPlaces.first);
    }

    return selected;
  }

  static List<List<Map<String, dynamic>>> groupByDays(List<Map<String, dynamic>> places, int days) {
    if (days <= 0 || places.isEmpty) return [];
    
    // Greedy clustering by proximity
    List<Map<String, dynamic>> remaining = List.from(places);
    List<List<Map<String, dynamic>>> result = [];
    
    int placesPerDay = (places.length / days).ceil();
    if (placesPerDay == 0) placesPerDay = 1;

    for (int i = 0; i < days; i++) {
      if (remaining.isEmpty) {
        result.add([]);
        continue;
      }

      List<Map<String, dynamic>> currentDay = [];
      
      // Pick the first available place as cluster center
      Map<String, dynamic> center = remaining.removeAt(0);
      currentDay.add(center);

      // Find closest remaining places
      while (currentDay.length < placesPerDay && remaining.isNotEmpty) {
        remaining.sort((a, b) => calculateDistance(center, a).compareTo(calculateDistance(center, b)));
        currentDay.add(remaining.removeAt(0));
      }

      result.add(currentDay);
    }

    return result;
  }

  static Map<String, dynamic> buildSmartTrip(List<Map<String, dynamic>> places, int days, int totalBudget) {
    // 1. Group into days
    final grouped = groupByDays(places, days);

    // 2. Apply budget per day
    final dailyBudget = days > 0 ? totalBudget ~/ days : totalBudget;
    final budgetedDays = grouped.map((dayPlaces) {
      return optimizeBudget(dayPlaces, dailyBudget);
    }).toList();

    // 3. Collect final places
    List<Map<String, dynamic>> finalPlaces = [];
    for (var day in budgetedDays) {
      finalPlaces.addAll(day);
    }

    // 4. Assign transport
    List<String> transport = [];
    for (int i = 0; i < finalPlaces.length - 1; i++) {
      final dist = calculateDistance(finalPlaces[i], finalPlaces[i + 1]);
      transport.add(chooseTransport(dist));
    }

    return {
      "days": budgetedDays,
      "transport": transport,
      "flatPlaces": finalPlaces,
    };
  }
}
