import 'package:travel_loco/models/place.dart';

// Time slot definitions (24‑hour clock)
const Map<String, Map<String, int>> timeSlots = {
  'morning': {'start': 8, 'end': 12},
  'afternoon': {'start': 12, 'end': 17},
  'evening': {'start': 17, 'end': 22},
};

/// Assign places to their preferred time slot based on the `bestTime` field.
Map<String, List<Place>> assignToSlots(List<Place> places) {
  final Map<String, List<Place>> slots = {
    'morning': [],
    'afternoon': [],
    'evening': [],
  };
  for (var p in places) {
    final best = (p as dynamic).bestTime as String? ?? 'afternoon';
    slots[best]?.add(p);
  }
  return slots;
}

/// Fit a list of places into a slot respecting a minute budget.
/// `travelBuffer` minutes are added after each place to account for movement.
List<Place> fitIntoSlot(List<Place> places, int maxMinutes, {int travelBuffer = 30}) {
  int total = 0;
  final List<Place> result = [];
  for (var p in places) {
    final duration = (p as dynamic).duration as int? ?? 0;
    if (total + duration + travelBuffer <= maxMinutes) {
      result.add(p);
      total += duration + travelBuffer;
    }
  }
  return result;
}

/// Build a full‑day itinerary from a flat list of places.
Map<String, List<Place>> buildDayPlan(List<Place> places) {
  final slots = assignToSlots(places);
  return {
    'morning': fitIntoSlot(slots['morning']!, 240), // 4 hrs
    'afternoon': fitIntoSlot(slots['afternoon']!, 300), // 5 hrs
    'evening': fitIntoSlot(slots['evening']!, 240), // 4 hrs
  };
}
