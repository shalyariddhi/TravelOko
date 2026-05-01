class Destination {
  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final double rating;
  final String description;
  final double price;

  Destination({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.rating,
    required this.description,
    required this.price,
  });

  factory Destination.fromMap(Map<String, dynamic> data, String documentId) {
    return Destination(
      id: documentId,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/400x300',
      rating: (data['rating'] ?? 0.0).toDouble(),
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'imageUrl': imageUrl,
      'rating': rating,
      'description': description,
      'price': price,
    };
  }
}
