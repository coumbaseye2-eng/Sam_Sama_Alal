import 'transaction_type.dart';

class AppTransaction {
  const AppTransaction({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.category,
    required this.createdAt,
    this.paymentMethod = 'Espèces',
    this.stockItemId,
    this.productName,
    this.quantity = 1,
    this.unitPrice = 0,
    this.synced = false,
  });

  final String id;
  final String uid;
  final TransactionType type;
  final int amount;
  final String category;
  final DateTime createdAt;
  final String paymentMethod;
  final String? stockItemId;
  final String? productName;
  final int quantity;
  final int unitPrice;
  final bool synced;

  int get signedAmount => type == TransactionType.sale ? amount : -amount;

  AppTransaction copyWith({
    bool? synced,
    String? paymentMethod,
    String? stockItemId,
    String? productName,
    int? quantity,
    int? unitPrice,
  }) {
    return AppTransaction(
      id: id,
      uid: uid,
      type: type,
      amount: amount,
      category: category,
      createdAt: createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stockItemId: stockItemId ?? this.stockItemId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      synced: synced ?? this.synced,
    );
  }

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      id: json['id'] as String,
      uid: json['uid'] as String,
      type: TransactionType.fromStorageValue(json['type'] as String),
      amount: json['amount'] as int,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      paymentMethod: json['paymentMethod'] as String? ?? 'Espèces',
      stockItemId: json['stockItemId'] as String?,
      productName: json['productName'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: json['unitPrice'] as int? ?? 0,
      synced: json['synced'] as bool? ?? false,
    );
  }

  factory AppTransaction.fromFirestore(Map<String, dynamic> json) {
    final rawDate = json['dateHeure'] ?? json['createdAt'];
    final amountValue = json['montant'] ?? json['amount'] ?? 0;

    return AppTransaction(
      id: json['id'] as String,
      uid: json['uid'] as String,
      type: TransactionType.fromStorageValue(json['type'] as String),
      amount: amountValue is int ? amountValue : (amountValue as num).toInt(),
      category: (json['categorie'] ?? json['category'] ?? 'Autre') as String,
      createdAt:
          rawDate is DateTime ? rawDate : DateTime.parse(rawDate as String),
      paymentMethod: (json['moyenPaiement'] ??
          json['paymentMethod'] ??
          'Espèces') as String,
      stockItemId: json['stockItemId'] as String?,
      productName: json['productName'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: json['unitPrice'] as int? ?? 0,
      synced: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'type': type.storageValue,
      'amount': amount,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'paymentMethod': paymentMethod,
      'stockItemId': stockItemId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'synced': synced,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'uid': uid,
      'type': type.storageValue,
      'montant': amount,
      'categorie': category,
      'dateHeure': createdAt.toIso8601String(),
      'moyenPaiement': paymentMethod,
      'stockItemId': stockItemId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'synced': true,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
