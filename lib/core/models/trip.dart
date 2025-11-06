/// 旅行计划模型
class Trip {
  final int? id;
  final String destination;
  final String startDate;
  final String endDate;
  final double budget;
  final String status; // planned, ongoing, completed
  final String? description;
  final String? coverImage;
  final DateTime createdAt;

  Trip({
    this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    this.status = 'planned',
    this.description,
    this.coverImage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination': destination,
      'start_date': startDate,
      'end_date': endDate,
      'budget': budget,
      'status': status,
      'description': description,
      'cover_image': coverImage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as int?,
      destination: map['destination'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      budget: (map['budget'] as num).toDouble(),
      status: map['status'] as String? ?? 'planned',
      description: map['description'] as String?,
      coverImage: map['cover_image'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Trip copyWith({
    int? id,
    String? destination,
    String? startDate,
    String? endDate,
    double? budget,
    String? status,
    String? description,
    String? coverImage,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
