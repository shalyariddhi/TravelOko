import 'itinerary_option.dart';
import 'expense.dart';
import 'packing_item.dart';

class Trip {
  final String id;
  final String title;
  final String destination;
  final String imageUrl;
  final String organizerId;
  final String organizerName;
  final String organizerAvatar;
  final int budget;
  final int durationDays;
  final DateTime startDate;
  final int totalSeats;
  final int seatsLeft;
  final bool isOnlyGirls;
  final bool isExclusive;
  final List<String> tags;
  final String description;
  final List<ItineraryOption> itineraries;
  final List<Expense> expenses;
  final List<PackingItem> packingList;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.imageUrl,
    required this.organizerId,
    required this.organizerName,
    required this.organizerAvatar,
    required this.budget,
    required this.durationDays,
    required this.startDate,
    required this.totalSeats,
    required this.seatsLeft,
    this.isOnlyGirls = false,
    this.isExclusive = false,
    this.tags = const [],
    this.description = '',
    this.itineraries = const [],
    this.expenses = const [],
    this.packingList = const [],
  });

  factory Trip.fromMap(Map<String, dynamic> data, String id) {
    return Trip(
      id: id,
      title: data['title'] ?? '',
      destination: data['destination'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      organizerAvatar: data['organizerAvatar'] ?? '',
      budget: (data['budget'] ?? 0).toInt(),
      durationDays: (data['durationDays'] ?? 1).toInt(),
      startDate: data['startDate'] != null
          ? (data['startDate'] as dynamic).toDate()
          : DateTime.now(),
      totalSeats: (data['totalSeats'] ?? 10).toInt(),
      seatsLeft: (data['seatsLeft'] ?? 10).toInt(),
      isOnlyGirls: data['isOnlyGirls'] ?? false,
      isExclusive: data['isExclusive'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      description: data['description'] ?? '',
      itineraries: (data['itineraries'] as List<dynamic>?)
              ?.map((i) => ItineraryOption.fromMap(i, i['id'] ?? ''))
              .toList() ??
          [],
      expenses: (data['expenses'] as List<dynamic>?)
              ?.map((e) => Expense.fromMap(e, e['id'] ?? ''))
              .toList() ??
          [],
      packingList: (data['packingList'] as List<dynamic>?)
              ?.map((p) => PackingItem.fromMap(p, p['id'] ?? ''))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'destination': destination,
      'imageUrl': imageUrl,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerAvatar': organizerAvatar,
      'budget': budget,
      'durationDays': durationDays,
      'startDate': startDate,
      'totalSeats': totalSeats,
      'seatsLeft': seatsLeft,
      'isOnlyGirls': isOnlyGirls,
      'isExclusive': isExclusive,
      'tags': tags,
      'description': description,
      'itineraries': itineraries.map((i) => i.toMap()).toList(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'packingList': packingList.map((p) => p.toMap()).toList(),
    };
  }
}
