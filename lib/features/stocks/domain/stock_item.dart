class StockItem {
  const StockItem({
    required this.id,
    required this.uid,
    required this.name,
    required this.category,
    required this.quantity,
    this.unitPrice = 0,
    this.alertThreshold = 3,
    required this.updatedAt,
    this.isArchived = false,
  });

  final String id;
  final String uid;
  final String name;
  final String category;
  final int quantity;
  final int unitPrice;
  final int alertThreshold;
  final DateTime updatedAt;
  final bool isArchived;

  bool get isLow => quantity <= alertThreshold;

  StockItem copyWith({
    String? name,
    String? category,
    int? quantity,
    int? unitPrice,
    int? alertThreshold,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return StockItem(
      id: id,
      uid: uid,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String,
      uid: json['uid'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      unitPrice: json['unitPrice'] as int? ?? 0,
      alertThreshold: json['alertThreshold'] as int? ?? 3,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'alertThreshold': alertThreshold,
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
    };
  }
}
