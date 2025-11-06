/// 景点模型
class Attraction {
  final int? id;
  final int tripId;
  final String name;
  final String location;
  final String category; // scenic, museum, restaurant, shopping, etc.
  final String? description;
  final String? imageUrl;
  final double? rating;
  final double? price;
  final String? notes;
  final bool visited;
  final DateTime createdAt;

  Attraction({
    this.id,
    required this.tripId,
    required this.name,
    required this.location,
    required this.category,
    this.description,
    this.imageUrl,
    this.rating,
    this.price,
    this.notes,
    this.visited = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'location': location,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'price': price,
      'notes': notes,
      'visited': visited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Attraction.fromMap(Map<String, dynamic> map) {
    return Attraction(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      name: map['name'] as String,
      location: map['location'] as String,
      category: map['category'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      visited: (map['visited'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Attraction copyWith({
    int? id,
    int? tripId,
    String? name,
    String? location,
    String? category,
    String? description,
    String? imageUrl,
    double? rating,
    double? price,
    String? notes,
    bool? visited,
    DateTime? createdAt,
  }) {
    return Attraction(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      location: location ?? this.location,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      visited: visited ?? this.visited,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
