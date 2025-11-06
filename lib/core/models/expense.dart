/// 花费记录模型
class Expense {
  final int? id;
  final int tripId;
  final String category; // transportation, accommodation, food, attraction, shopping, other
  final double amount;
  final String currency;
  final String date;
  final String? description;
  final String? receipt; // 收据图片路径
  final DateTime createdAt;

  Expense({
    this.id,
    required this.tripId,
    required this.category,
    required this.amount,
    this.currency = 'CNY',
    required this.date,
    this.description,
    this.receipt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'category': category,
      'amount': amount,
      'currency': currency,
      'date': date,
      'description': description,
      'receipt': receipt,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'CNY',
      date: map['date'] as String,
      description: map['description'] as String?,
      receipt: map['receipt'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Expense copyWith({
    int? id,
    int? tripId,
    String? category,
    double? amount,
    String? currency,
    String? date,
    String? description,
    String? receipt,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      description: description ?? this.description,
      receipt: receipt ?? this.receipt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
