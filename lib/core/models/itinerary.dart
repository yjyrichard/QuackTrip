/// 行程安排模型
class Itinerary {
  final int? id;
  final int tripId;
  final int day; // 第几天
  final String time; // 时间，如 "09:00"
  final String activity;
  final String location;
  final String? description;
  final int? attractionId; // 关联的景点ID
  final bool completed;
  final DateTime createdAt;

  Itinerary({
    this.id,
    required this.tripId,
    required this.day,
    required this.time,
    required this.activity,
    required this.location,
    this.description,
    this.attractionId,
    this.completed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'day': day,
      'time': time,
      'activity': activity,
      'location': location,
      'description': description,
      'attraction_id': attractionId,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Itinerary.fromMap(Map<String, dynamic> map) {
    return Itinerary(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      day: map['day'] as int,
      time: map['time'] as String,
      activity: map['activity'] as String,
      location: map['location'] as String,
      description: map['description'] as String?,
      attractionId: map['attraction_id'] as int?,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Itinerary copyWith({
    int? id,
    int? tripId,
    int? day,
    String? time,
    String? activity,
    String? location,
    String? description,
    int? attractionId,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Itinerary(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      day: day ?? this.day,
      time: time ?? this.time,
      activity: activity ?? this.activity,
      location: location ?? this.location,
      description: description ?? this.description,
      attractionId: attractionId ?? this.attractionId,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
