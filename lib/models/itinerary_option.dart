class ItineraryOption {
  final String id;
  final String title;
  final String description;
  final int price;

  ItineraryOption({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  factory ItineraryOption.fromMap(Map<String, dynamic> data, String id) {
    return ItineraryOption(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
    };
  }
}
