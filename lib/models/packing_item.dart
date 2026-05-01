class PackingItem {
  final String id;
  final String name;
  final String category;
  bool isPacked;

  PackingItem({
    required this.id,
    required this.name,
    required this.category,
    this.isPacked = false,
  });

  factory PackingItem.fromMap(Map<String, dynamic> data, String id) {
    return PackingItem(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      isPacked: data['isPacked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'isPacked': isPacked,
    };
  }
}
