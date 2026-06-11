class PersonalNote {
  const PersonalNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.kind = PersonalNoteKind.note,
    this.debtDirection = DebtDirection.customerOwesMe,
    this.clientName = '',
    this.phoneNumber = '',
    this.nationalId = '',
    this.photoPath = '',
    this.initialAmount = 0,
    this.payments = const [],
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PersonalNoteKind kind;
  final DebtDirection debtDirection;
  final String clientName;
  final String phoneNumber;
  final String nationalId;
  final String photoPath;
  final int initialAmount;
  final List<DebtPayment> payments;

  int get paidAmount {
    return payments.fold<int>(0, (sum, payment) => sum + payment.amount);
  }

  int get remainingAmount {
    final remaining = initialAmount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isDebtPaid => kind == PersonalNoteKind.debt && remainingAmount == 0;

  PersonalNote copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    PersonalNoteKind? kind,
    DebtDirection? debtDirection,
    String? clientName,
    String? phoneNumber,
    String? nationalId,
    String? photoPath,
    int? initialAmount,
    List<DebtPayment>? payments,
  }) {
    return PersonalNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kind: kind ?? this.kind,
      debtDirection: debtDirection ?? this.debtDirection,
      clientName: clientName ?? this.clientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalId: nationalId ?? this.nationalId,
      photoPath: photoPath ?? this.photoPath,
      initialAmount: initialAmount ?? this.initialAmount,
      payments: payments ?? this.payments,
    );
  }

  factory PersonalNote.fromJson(Map<String, dynamic> json) {
    return PersonalNote(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sans titre',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      kind: PersonalNoteKindX.fromName(json['kind'] as String?),
      debtDirection: DebtDirectionX.fromName(json['debtDirection'] as String?),
      clientName: json['clientName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      nationalId: json['nationalId'] as String? ?? '',
      photoPath: json['photoPath'] as String? ?? '',
      initialAmount: (json['initialAmount'] as num?)?.toInt() ?? 0,
      payments: (json['payments'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => DebtPayment.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'kind': kind.name,
      'debtDirection': debtDirection.name,
      'clientName': clientName,
      'phoneNumber': phoneNumber,
      'nationalId': nationalId,
      'photoPath': photoPath,
      'initialAmount': initialAmount,
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };
  }
}

enum PersonalNoteKind { note, debt }

extension PersonalNoteKindX on PersonalNoteKind {
  static PersonalNoteKind fromName(String? value) {
    return PersonalNoteKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => PersonalNoteKind.note,
    );
  }
}

enum DebtDirection { customerOwesMe, iOweCustomer }

extension DebtDirectionX on DebtDirection {
  static DebtDirection fromName(String? value) {
    return DebtDirection.values.firstWhere(
      (direction) => direction.name == value,
      orElse: () => DebtDirection.customerOwesMe,
    );
  }
}

class DebtPayment {
  const DebtPayment({
    required this.id,
    required this.amount,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final int amount;
  final DateTime createdAt;
  final String note;

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }
}
