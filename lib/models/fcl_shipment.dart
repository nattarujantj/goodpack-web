/// One full container (เหมาตู้). Several factories (each an InternationalImport with
/// its own imp id) link to one shipment; shipping cost is owned here and allocated to
/// the linked imports by CBM share.
class FclShipment {
  final String id;
  final String fclCode;
  final DateTime shipmentDate;
  final String shippingCompanyId;
  final String shippingCompanyName;
  final double usdToThbRate;
  final List<FclCostLine> costLines;
  final double totalCostThb;
  final double totalCBM;
  final int linkedImportCount;
  final String status; // "open" | "closed"
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FclShipment({
    required this.id,
    required this.fclCode,
    required this.shipmentDate,
    required this.shippingCompanyId,
    required this.shippingCompanyName,
    required this.usdToThbRate,
    required this.costLines,
    required this.totalCostThb,
    required this.totalCBM,
    required this.linkedImportCount,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOpen => status == 'open';

  factory FclShipment.fromJson(Map<String, dynamic> json) {
    return FclShipment(
      id: json['id']?.toString() ?? '',
      fclCode: json['fclCode'] ?? '',
      shipmentDate: json['shipmentDate'] != null
          ? DateTime.parse(json['shipmentDate']).toLocal()
          : DateTime.now(),
      shippingCompanyId: json['shippingCompanyId'] ?? '',
      shippingCompanyName: json['shippingCompanyName'] ?? '',
      usdToThbRate: (json['usdToThbRate'] ?? 0).toDouble(),
      costLines: (json['costLines'] as List<dynamic>?)
              ?.map((e) => FclCostLine.fromJson(e))
              .toList() ??
          [],
      totalCostThb: (json['totalCostThb'] ?? 0).toDouble(),
      totalCBM: (json['totalCBM'] ?? 0).toDouble(),
      linkedImportCount: json['linkedImportCount'] ?? 0,
      status: json['status'] ?? 'open',
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class FclCostLine {
  final String name;
  final String currency; // "THB" | "USD"
  final double amount;
  final double usdRate;
  final double amountThb;

  FclCostLine({
    required this.name,
    required this.currency,
    required this.amount,
    this.usdRate = 0,
    this.amountThb = 0,
  });

  /// Computes the THB value of this line given the shipment's default rate,
  /// for client-side preview before the server recomputes.
  double computeThb(double defaultRate) {
    if (currency == 'USD') {
      final rate = usdRate > 0 ? usdRate : defaultRate;
      return amount * rate;
    }
    return amount;
  }

  factory FclCostLine.fromJson(Map<String, dynamic> json) {
    return FclCostLine(
      name: json['name'] ?? '',
      currency: json['currency'] ?? 'THB',
      amount: (json['amount'] ?? 0).toDouble(),
      usdRate: (json['usdRate'] ?? 0).toDouble(),
      amountThb: (json['amountThb'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'currency': currency,
      'amount': amount,
      'usdRate': usdRate,
      'amountThb': amountThb,
    };
  }

  FclCostLine copyWith({
    String? name,
    String? currency,
    double? amount,
    double? usdRate,
  }) {
    return FclCostLine(
      name: name ?? this.name,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      usdRate: usdRate ?? this.usdRate,
      amountThb: amountThb,
    );
  }
}

class FclShipmentRequest {
  final DateTime shipmentDate;
  final String shippingCompanyId;
  final double usdToThbRate;
  final List<FclCostLine> costLines;
  final String? notes;

  FclShipmentRequest({
    required this.shipmentDate,
    required this.shippingCompanyId,
    required this.usdToThbRate,
    required this.costLines,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'shipmentDate': shipmentDate.toUtc().toIso8601String(),
      'shippingCompanyId': shippingCompanyId,
      'usdToThbRate': usdToThbRate,
      'costLines': costLines.map((e) => e.toJson()).toList(),
      if (notes != null) 'notes': notes,
    };
  }
}
