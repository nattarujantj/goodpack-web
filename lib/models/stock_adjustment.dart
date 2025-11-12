class StockAdjustment {
  final String id;
  final String productId;
  final String productName;
  final String skuId;
  final String adjustmentType; // "add" or "reduce"
  final String stockType; // "vat", "nonvat", or "actualstock"
  final int quantity;
  
  // Before values
  final int beforeVATPurchased;
  final int beforeVATSold;
  final int beforeVATRemaining;
  final int beforeNonVATPurchased;
  final int beforeNonVATSold;
  final int beforeNonVATRemaining;
  final int beforeActualStock;
  
  // After values
  final int afterVATPurchased;
  final int afterVATSold;
  final int afterVATRemaining;
  final int afterNonVATPurchased;
  final int afterNonVATSold;
  final int afterNonVATRemaining;
  final int afterActualStock;
  
  final String sourceType; // "purchase", "sale", "adjustment", "migration"
  final String? sourceId;
  final String? sourceCode;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  StockAdjustment({
    required this.id,
    required this.productId,
    required this.productName,
    required this.skuId,
    required this.adjustmentType,
    required this.stockType,
    required this.quantity,
    required this.beforeVATPurchased,
    required this.beforeVATSold,
    required this.beforeVATRemaining,
    required this.beforeNonVATPurchased,
    required this.beforeNonVATSold,
    required this.beforeNonVATRemaining,
    required this.beforeActualStock,
    required this.afterVATPurchased,
    required this.afterVATSold,
    required this.afterVATRemaining,
    required this.afterNonVATPurchased,
    required this.afterNonVATSold,
    required this.afterNonVATRemaining,
    required this.afterActualStock,
    required this.sourceType,
    this.sourceId,
    this.sourceCode,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  factory StockAdjustment.fromJson(Map<String, dynamic> json) {
    return StockAdjustment(
      id: json['id'] ?? json['_id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      skuId: json['skuId'] ?? '',
      adjustmentType: json['adjustmentType'] ?? '',
      stockType: json['stockType'] ?? '',
      quantity: json['quantity'] ?? 0,
      beforeVATPurchased: json['beforeVATPurchased'] ?? 0,
      beforeVATSold: json['beforeVATSold'] ?? 0,
      beforeVATRemaining: json['beforeVATRemaining'] ?? 0,
      beforeNonVATPurchased: json['beforeNonVATPurchased'] ?? 0,
      beforeNonVATSold: json['beforeNonVATSold'] ?? 0,
      beforeNonVATRemaining: json['beforeNonVATRemaining'] ?? 0,
      beforeActualStock: json['beforeActualStock'] ?? 0,
      afterVATPurchased: json['afterVATPurchased'] ?? 0,
      afterVATSold: json['afterVATSold'] ?? 0,
      afterVATRemaining: json['afterVATRemaining'] ?? 0,
      afterNonVATPurchased: json['afterNonVATPurchased'] ?? 0,
      afterNonVATSold: json['afterNonVATSold'] ?? 0,
      afterNonVATRemaining: json['afterNonVATRemaining'] ?? 0,
      afterActualStock: json['afterActualStock'] ?? 0,
      sourceType: json['sourceType'] ?? '',
      sourceId: json['sourceId'],
      sourceCode: json['sourceCode'],
      notes: json['notes'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'skuId': skuId,
      'adjustmentType': adjustmentType,
      'stockType': stockType,
      'quantity': quantity,
      'beforeVATPurchased': beforeVATPurchased,
      'beforeVATSold': beforeVATSold,
      'beforeVATRemaining': beforeVATRemaining,
      'beforeNonVATPurchased': beforeNonVATPurchased,
      'beforeNonVATSold': beforeNonVATSold,
      'beforeNonVATRemaining': beforeNonVATRemaining,
      'beforeActualStock': beforeActualStock,
      'afterVATPurchased': afterVATPurchased,
      'afterVATSold': afterVATSold,
      'afterVATRemaining': afterVATRemaining,
      'afterNonVATPurchased': afterNonVATPurchased,
      'afterNonVATSold': afterNonVATSold,
      'afterNonVATRemaining': afterNonVATRemaining,
      'afterActualStock': afterActualStock,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'sourceCode': sourceCode,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get adjustmentTypeDisplay {
    return adjustmentType == 'add' ? 'เพิ่ม' : 'ลด';
  }

  String get stockTypeDisplay {
    switch (stockType) {
      case 'vat':
        return 'VAT';
      case 'nonvat':
        return 'Non-VAT';
      case 'actualstock':
        return 'สินค้าคงเหลือจริง';
      default:
        return stockType;
    }
  }

  String get sourceTypeDisplay {
    switch (sourceType) {
      case 'purchase':
        return 'รายการซื้อ';
      case 'sale':
        return 'รายการขาย';
      case 'adjustment':
        return 'แก้ไขสต็อก';
      case 'migration':
        return 'Migration';
      default:
        return sourceType;
    }
  }
}

class StockAdjustmentRequest {
  final String adjustmentType; // "add" or "reduce"
  final String stockType; // "vat", "nonvat", or "actualstock"
  final int quantity;
  final String? notes;

  StockAdjustmentRequest({
    required this.adjustmentType,
    required this.stockType,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'adjustmentType': adjustmentType,
      'stockType': stockType,
      'quantity': quantity,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

