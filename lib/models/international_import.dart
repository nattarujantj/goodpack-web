class InternationalImport {
  final String id;
  final String importCode;
  final DateTime importDate;
  final String importType; // "LCL" or "FCL"
  final String supplierId;
  final String supplierName;
  final String shippingCompanyId;
  final String shippingCompanyName;
  final double usdToThbRate;
  final double pricePerCBM;
  final List<FCLCostDetail> fclCostDetails;
  final double totalFCLCost;
  final List<ImportItem> items;
  final double totalCBM;
  final double totalShippingCost;
  final double totalProductCost;
  final double grandTotal;
  final String status;
  final String? purchaseId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  InternationalImport({
    required this.id,
    required this.importCode,
    required this.importDate,
    required this.importType,
    required this.supplierId,
    required this.supplierName,
    required this.shippingCompanyId,
    required this.shippingCompanyName,
    required this.usdToThbRate,
    required this.pricePerCBM,
    required this.fclCostDetails,
    required this.totalFCLCost,
    required this.items,
    required this.totalCBM,
    required this.totalShippingCost,
    required this.totalProductCost,
    required this.grandTotal,
    required this.status,
    this.purchaseId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InternationalImport.fromJson(Map<String, dynamic> json) {
    return InternationalImport(
      id: json['id']?.toString() ?? '',
      importCode: json['importCode'] ?? '',
      importDate: json['importDate'] != null
          ? DateTime.parse(json['importDate'])
          : DateTime.now(),
      importType: json['importType'] ?? 'LCL',
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      shippingCompanyId: json['shippingCompanyId'] ?? '',
      shippingCompanyName: json['shippingCompanyName'] ?? '',
      usdToThbRate: (json['usdToThbRate'] ?? 0).toDouble(),
      pricePerCBM: (json['pricePerCBM'] ?? 0).toDouble(),
      fclCostDetails: (json['fclCostDetails'] as List<dynamic>?)
              ?.map((e) => FCLCostDetail.fromJson(e))
              .toList() ??
          [],
      totalFCLCost: (json['totalFCLCost'] ?? 0).toDouble(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ImportItem.fromJson(e))
              .toList() ??
          [],
      totalCBM: (json['totalCBM'] ?? 0).toDouble(),
      totalShippingCost: (json['totalShippingCost'] ?? 0).toDouble(),
      totalProductCost: (json['totalProductCost'] ?? 0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      purchaseId: json['purchaseId'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'importCode': importCode,
      'importDate': importDate.toIso8601String(),
      'importType': importType,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'shippingCompanyId': shippingCompanyId,
      'shippingCompanyName': shippingCompanyName,
      'usdToThbRate': usdToThbRate,
      'pricePerCBM': pricePerCBM,
      'fclCostDetails': fclCostDetails.map((e) => e.toJson()).toList(),
      'totalFCLCost': totalFCLCost,
      'items': items.map((e) => e.toJson()).toList(),
      'totalCBM': totalCBM,
      'totalShippingCost': totalShippingCost,
      'totalProductCost': totalProductCost,
      'grandTotal': grandTotal,
      'status': status,
      'purchaseId': purchaseId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class FCLCostDetail {
  final String name;
  final double amount;

  FCLCostDetail({required this.name, required this.amount});

  factory FCLCostDetail.fromJson(Map<String, dynamic> json) {
    return FCLCostDetail(
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'amount': amount};
  }
}

class ImportItem {
  final String productId;
  final String productName;
  final String productCode;
  final double usdPricePerUnit;
  final int quantity;
  final double boxWidth;
  final double boxLength;
  final double boxHeight;
  final double cbm;
  final double shippingCostPerUnit;
  final double commission;
  final double costPerUnitBeforeVAT;
  final double vatPerUnit;
  final double costPerUnitAfterVAT;
  final double totalCost;

  ImportItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.usdPricePerUnit,
    required this.quantity,
    required this.boxWidth,
    required this.boxLength,
    required this.boxHeight,
    required this.cbm,
    required this.shippingCostPerUnit,
    required this.commission,
    required this.costPerUnitBeforeVAT,
    required this.vatPerUnit,
    required this.costPerUnitAfterVAT,
    required this.totalCost,
  });

  factory ImportItem.fromJson(Map<String, dynamic> json) {
    return ImportItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productCode: json['productCode'] ?? '',
      usdPricePerUnit: (json['usdPricePerUnit'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      boxWidth: (json['boxWidth'] ?? 0).toDouble(),
      boxLength: (json['boxLength'] ?? 0).toDouble(),
      boxHeight: (json['boxHeight'] ?? 0).toDouble(),
      cbm: (json['cbm'] ?? 0).toDouble(),
      shippingCostPerUnit: (json['shippingCostPerUnit'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      costPerUnitBeforeVAT: (json['costPerUnitBeforeVAT'] ?? 0).toDouble(),
      vatPerUnit: (json['vatPerUnit'] ?? 0).toDouble(),
      costPerUnitAfterVAT: (json['costPerUnitAfterVAT'] ?? 0).toDouble(),
      totalCost: (json['totalCost'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productCode': productCode,
      'usdPricePerUnit': usdPricePerUnit,
      'quantity': quantity,
      'boxWidth': boxWidth,
      'boxLength': boxLength,
      'boxHeight': boxHeight,
      'cbm': cbm,
      'shippingCostPerUnit': shippingCostPerUnit,
      'commission': commission,
      'costPerUnitBeforeVAT': costPerUnitBeforeVAT,
      'vatPerUnit': vatPerUnit,
      'costPerUnitAfterVAT': costPerUnitAfterVAT,
      'totalCost': totalCost,
    };
  }

  ImportItem copyWith({
    String? productId,
    String? productName,
    String? productCode,
    double? usdPricePerUnit,
    int? quantity,
    double? boxWidth,
    double? boxLength,
    double? boxHeight,
    double? cbm,
    double? shippingCostPerUnit,
    double? commission,
    double? costPerUnitBeforeVAT,
    double? vatPerUnit,
    double? costPerUnitAfterVAT,
    double? totalCost,
  }) {
    return ImportItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      usdPricePerUnit: usdPricePerUnit ?? this.usdPricePerUnit,
      quantity: quantity ?? this.quantity,
      boxWidth: boxWidth ?? this.boxWidth,
      boxLength: boxLength ?? this.boxLength,
      boxHeight: boxHeight ?? this.boxHeight,
      cbm: cbm ?? this.cbm,
      shippingCostPerUnit: shippingCostPerUnit ?? this.shippingCostPerUnit,
      commission: commission ?? this.commission,
      costPerUnitBeforeVAT: costPerUnitBeforeVAT ?? this.costPerUnitBeforeVAT,
      vatPerUnit: vatPerUnit ?? this.vatPerUnit,
      costPerUnitAfterVAT: costPerUnitAfterVAT ?? this.costPerUnitAfterVAT,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}

class InternationalImportRequest {
  final DateTime importDate;
  final String importType;
  final String supplierId;
  final String shippingCompanyId;
  final double usdToThbRate;
  final double pricePerCBM;
  final List<FCLCostDetail> fclCostDetails;
  final List<ImportItem> items;
  final String? notes;

  InternationalImportRequest({
    required this.importDate,
    required this.importType,
    required this.supplierId,
    required this.shippingCompanyId,
    required this.usdToThbRate,
    required this.pricePerCBM,
    required this.fclCostDetails,
    required this.items,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'importDate': importDate.toUtc().toIso8601String(),
      'importType': importType,
      'supplierId': supplierId,
      'shippingCompanyId': shippingCompanyId,
      'usdToThbRate': usdToThbRate,
      'pricePerCBM': pricePerCBM,
      'fclCostDetails': fclCostDetails.map((e) => e.toJson()).toList(),
      'items': items.map((e) => e.toJson()).toList(),
      if (notes != null) 'notes': notes,
    };
  }
}
