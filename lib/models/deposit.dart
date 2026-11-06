/// เงินมัดจำ: ลูกค้ามาวางมัดจำกับเรา (customer) หรือเราไปวางมัดจำกับซัพพลายเออร์ (supplier)
/// มัดจำหนึ่งก้อนทยอยหักได้จากหลายรายการขาย/รายการซื้อของคู่ค้าเจ้าเดียวกัน
class Deposit {
  static const String typeCustomer = 'customer';
  static const String typeSupplier = 'supplier';

  final String id;
  final String depositCode;
  final String type;
  final String partyId;
  final String partyName;
  final String partyCode;
  final double amount;
  final DateTime depositDate;
  final String? ourAccount;
  final String reference;
  final String notes;
  final double usedAmount;
  final double remainingAmount;
  final List<DepositUsage> usages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Deposit({
    required this.id,
    required this.depositCode,
    required this.type,
    required this.partyId,
    required this.partyName,
    this.partyCode = '',
    required this.amount,
    required this.depositDate,
    this.ourAccount,
    this.reference = '',
    this.notes = '',
    this.usedAmount = 0,
    double? remainingAmount,
    this.usages = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : remainingAmount = remainingAmount ?? amount;

  bool get isCustomer => type == typeCustomer;
  bool get isFullyUsed => remainingAmount <= 0.005;

  static String typeLabel(String type) =>
      type == typeSupplier ? 'เราวางมัดจำกับซัพพลายเออร์' : 'ลูกค้าวางมัดจำกับเรา';

  static String partyLabel(String type) => type == typeSupplier ? 'ซัพพลายเออร์' : 'ลูกค้า';

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: json['id'] ?? '',
      depositCode: json['depositCode'] ?? '',
      type: json['type'] ?? typeCustomer,
      partyId: json['partyId'] ?? '',
      partyName: json['partyName'] ?? '',
      partyCode: json['partyCode'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      depositDate: (DateTime.tryParse(json['depositDate'] ?? '') ?? DateTime.now()).toLocal(),
      ourAccount: json['ourAccount'],
      reference: json['reference'] ?? '',
      notes: json['notes'] ?? '',
      usedAmount: (json['usedAmount'] ?? 0).toDouble(),
      remainingAmount: (json['remainingAmount'] ?? json['amount'] ?? 0).toDouble(),
      usages: (json['usages'] as List<dynamic>?)
              ?.map((u) => DepositUsage.fromJson(u as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// การหักมัดจำหนึ่งครั้งในรายการขาย/ซื้อ (ประวัติการใช้มัดจำ)
class DepositUsage {
  final String docType; // "sale" หรือ "purchase"
  final String docId;
  final String docCode;
  final DateTime? docDate;
  final double amount;

  DepositUsage({
    required this.docType,
    required this.docId,
    required this.docCode,
    this.docDate,
    required this.amount,
  });

  bool get isSale => docType == 'sale';

  factory DepositUsage.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['docDate'] ?? '');
    return DepositUsage(
      docType: json['docType'] ?? '',
      docId: json['docId'] ?? '',
      docCode: json['docCode'] ?? '',
      docDate: date == null || date.year <= 1 ? null : date.toLocal(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

/// ยอดมัดจำที่หักในรายการขาย/ซื้อหนึ่งรายการ (เก็บไว้ในรายการขาย/ซื้อ)
class DepositApplication {
  final String depositId;
  final String depositCode;
  final double amount;

  const DepositApplication({
    required this.depositId,
    this.depositCode = '',
    required this.amount,
  });

  factory DepositApplication.fromJson(Map<String, dynamic> json) {
    return DepositApplication(
      depositId: json['depositId'] ?? '',
      depositCode: json['depositCode'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'depositId': depositId,
        'depositCode': depositCode,
        'amount': amount,
      };

  static List<DepositApplication> listFromJson(dynamic json) {
    if (json is! List) return [];
    return json
        .map((e) => DepositApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static double sum(List<DepositApplication> apps) =>
      apps.fold(0.0, (total, a) => total + a.amount);
}

class DepositRequest {
  final String? depositCode;
  final String type;
  final String partyId;
  final double amount;
  final DateTime depositDate;
  final String? ourAccount;
  final String reference;
  final String notes;

  DepositRequest({
    this.depositCode,
    required this.type,
    required this.partyId,
    required this.amount,
    required this.depositDate,
    this.ourAccount,
    this.reference = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        if (depositCode != null && depositCode!.trim().isNotEmpty) 'depositCode': depositCode!.trim(),
        'type': type,
        'partyId': partyId,
        'amount': amount,
        'depositDate': depositDate.toUtc().toIso8601String(),
        'ourAccount': (ourAccount == null || ourAccount!.isEmpty) ? null : ourAccount,
        'reference': reference,
        'notes': notes,
      };
}
