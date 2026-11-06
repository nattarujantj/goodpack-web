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
  final double amount; // ยอดเงินที่รับ/จ่ายจริง (รวม VAT ถ้ามี)
  /// มัดจำนี้ออกใบกำกับภาษีแล้ว: หักในรายการ VAT ก่อนคิด VAT
  final bool isVAT;
  final String vatType; // "exclusive" (VAT นอก) / "inclusive" (VAT ใน) ตอนกรอก
  final double amountBeforeVAT;
  final double vatAmount;
  final DateTime depositDate;
  final String? ourAccount;
  final String reference;
  final String notes;
  /// ยอดที่ใช้หักได้ทั้งหมด / ใช้ไป / คงเหลือ: มัดจำ VAT นับเป็นยอดก่อน VAT
  final double deductibleAmount;
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
    this.isVAT = false,
    this.vatType = '',
    double? amountBeforeVAT,
    this.vatAmount = 0,
    double? deductibleAmount,
    required this.depositDate,
    this.ourAccount,
    this.reference = '',
    this.notes = '',
    this.usedAmount = 0,
    double? remainingAmount,
    this.usages = const [],
    required this.createdAt,
    required this.updatedAt,
  })  : amountBeforeVAT = amountBeforeVAT ?? amount,
        deductibleAmount = deductibleAmount ?? (isVAT ? (amountBeforeVAT ?? amount) : amount),
        remainingAmount = remainingAmount ?? (isVAT ? (amountBeforeVAT ?? amount) : amount);

  bool get isCustomer => type == typeCustomer;
  /// ส่วนต่างจากการปัดเศษที่ยอมให้หักเกินยอดคงเหลือได้ (เท่ากับ server: 5 สตางค์)
  /// เช่น มัดจำ 10,000 รวม VAT แบ่งหักใบ VAT ใน 5,000 สองใบ ยอดก่อน VAT รวมกันเกิน 1 สตางค์
  static const double roundingTolerance = 0.05;

  bool get isFullyUsed => remainingAmount <= roundingTolerance;

  /// ยอดคงเหลือสำหรับแสดงผล (ไม่ติดลบจากการปัดเศษ)
  double get displayRemaining => remainingAmount < 0 ? 0 : remainingAmount;

  /// ยอดรวม VAT โดยประมาณของยอดก่อน VAT (ใช้แสดงให้เทียบกับเงินที่รับจริง)
  static double withVAT(double beforeVAT) => (beforeVAT * 1.07 * 100).roundToDouble() / 100;

  static String typeLabel(String type) =>
      type == typeSupplier ? 'เราวางมัดจำกับซัพพลายเออร์' : 'ลูกค้าวางมัดจำกับเรา';

  static String partyLabel(String type) => type == typeSupplier ? 'ซัพพลายเออร์' : 'ลูกค้า';

  /// ข้อความต่อท้ายยอดคงเหลือ ให้รู้ว่าเป็นยอดก่อน VAT หรือไม่
  String get balanceUnitLabel => isVAT ? ' (ก่อน VAT)' : '';

  /// แยกยอดก่อน VAT / VAT / ยอดรวม จากยอดที่กรอก (สูตรเดียวกับ server)
  /// exclusive: ยอดที่กรอกคือยอดก่อน VAT, inclusive: ยอดที่กรอกรวม VAT แล้ว
  static ({double beforeVAT, double vat, double total}) calculateVAT(
      double entered, bool isVAT, String vatType) {
    double r2(double v) => (v * 100).roundToDouble() / 100;
    entered = r2(entered);
    if (!isVAT) return (beforeVAT: entered, vat: 0.0, total: entered);
    if (vatType == 'inclusive') {
      final before = r2(entered / 1.07);
      return (beforeVAT: before, vat: r2(entered - before), total: entered);
    }
    final vat = r2(entered * 0.07);
    return (beforeVAT: entered, vat: vat, total: r2(entered + vat));
  }

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: json['id'] ?? '',
      depositCode: json['depositCode'] ?? '',
      type: json['type'] ?? typeCustomer,
      partyId: json['partyId'] ?? '',
      partyName: json['partyName'] ?? '',
      partyCode: json['partyCode'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      isVAT: json['isVAT'] ?? false,
      vatType: json['vatType'] ?? '',
      amountBeforeVAT: (json['amountBeforeVAT'] ?? json['amount'] ?? 0).toDouble(),
      vatAmount: (json['vatAmount'] ?? 0).toDouble(),
      deductibleAmount: json['deductibleAmount'] != null ? (json['deductibleAmount']).toDouble() : null,
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
  /// true = มัดจำที่ออกใบกำกับภาษีแล้ว: amount คือยอดก่อน VAT และหักก่อนคิด VAT
  final bool beforeVAT;

  const DepositApplication({
    required this.depositId,
    this.depositCode = '',
    required this.amount,
    this.beforeVAT = false,
  });

  factory DepositApplication.fromJson(Map<String, dynamic> json) {
    return DepositApplication(
      depositId: json['depositId'] ?? '',
      depositCode: json['depositCode'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      beforeVAT: json['beforeVAT'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'depositId': depositId,
        'depositCode': depositCode,
        'amount': amount,
        'beforeVAT': beforeVAT,
      };

  static List<DepositApplication> listFromJson(dynamic json) {
    if (json is! List) return [];
    return json
        .map((e) => DepositApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static double sum(List<DepositApplication> apps) =>
      apps.fold(0.0, (total, a) => total + a.amount);

  /// ยอดมัดจำที่หักก่อน VAT (มัดจำที่ออกใบกำกับภาษีแล้ว)
  static double sumBeforeVAT(List<DepositApplication> apps) =>
      sum(apps.where((a) => a.beforeVAT).toList());

  /// ยอดมัดจำที่หักหลัง VAT (มัดจำไม่มี VAT)
  static double sumAfterVAT(List<DepositApplication> apps) =>
      sum(apps.where((a) => !a.beforeVAT).toList());
}

class DepositRequest {
  final String? depositCode;
  final String type;
  final String partyId;
  final double amount; // ยอดที่กรอก (ไม่มี VAT / VAT นอก = ก่อน VAT, VAT ใน = รวม VAT)
  final bool isVAT;
  final String vatType;
  final DateTime depositDate;
  final String? ourAccount;
  final String reference;
  final String notes;

  DepositRequest({
    this.depositCode,
    required this.type,
    required this.partyId,
    required this.amount,
    this.isVAT = false,
    this.vatType = 'exclusive',
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
        'isVAT': isVAT,
        'vatType': vatType,
        'depositDate': depositDate.toUtc().toIso8601String(),
        'ourAccount': (ourAccount == null || ourAccount!.isEmpty) ? null : ourAccount,
        'reference': reference,
        'notes': notes,
      };
}
