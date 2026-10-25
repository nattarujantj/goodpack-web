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
  final String? fclShipmentId;
  // ข้อมูลใบขนสินค้า (FCL): เมื่อกรอก VAT แล้ว VAT จะใช้ยอดจริงแทนการประมาณ 7%
  final ImportCustoms? customs;
  final String vatSource; // "customs" | "estimated"
  final List<ImportItem> items;
  final double totalCBM;
  final double totalShippingCost;
  final double totalProductCost;
  final double totalImportDuty;
  final double totalGoodsVAT;
  final double totalFreightVAT;
  final double totalVAT;
  final double grandTotal;
  final String status;
  final String? purchaseId;
  final bool? purchaseIsVAT;
  final String? purchaseVatMode; // "vat" | "nonvat" | "import"
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
    this.fclShipmentId,
    this.customs,
    this.vatSource = 'estimated',
    required this.items,
    required this.totalCBM,
    required this.totalShippingCost,
    required this.totalProductCost,
    this.totalImportDuty = 0,
    this.totalGoodsVAT = 0,
    this.totalFreightVAT = 0,
    this.totalVAT = 0,
    required this.grandTotal,
    required this.status,
    this.purchaseId,
    this.purchaseIsVAT,
    this.purchaseVatMode,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InternationalImport.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((e) => ImportItem.fromJson(e))
            .toList() ??
        <ImportItem>[];
    // รายการที่บันทึกก่อนมี totalVAT: รวมจาก VAT ต่อชิ้นของแต่ละสินค้า (ประมาณการ 7% เดิม)
    final totalVAT = json['totalVAT'] != null
        ? (json['totalVAT'] as num).toDouble()
        : items.fold(0.0, (s, i) => s + i.vatPerUnit * i.quantity);
    return InternationalImport(
      id: json['id']?.toString() ?? '',
      importCode: json['importCode'] ?? '',
      importDate: json['importDate'] != null
          ? DateTime.parse(json['importDate']).toLocal()
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
      fclShipmentId: json['fclShipmentId'],
      customs: json['customs'] != null
          ? ImportCustoms.fromJson(json['customs'] as Map<String, dynamic>)
          : null,
      vatSource: json['vatSource'] ?? 'estimated',
      items: items,
      totalCBM: (json['totalCBM'] ?? 0).toDouble(),
      totalShippingCost: (json['totalShippingCost'] ?? 0).toDouble(),
      totalProductCost: (json['totalProductCost'] ?? 0).toDouble(),
      totalImportDuty: (json['totalImportDuty'] ?? 0).toDouble(),
      totalGoodsVAT: (json['totalGoodsVAT'] ?? 0).toDouble(),
      totalFreightVAT: (json['totalFreightVAT'] ?? 0).toDouble(),
      totalVAT: totalVAT,
      grandTotal: (json['grandTotal'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      purchaseId: json['purchaseId'],
      purchaseIsVAT: json['purchaseIsVAT'],
      purchaseVatMode: json['purchaseVatMode'],
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
      'fclShipmentId': fclShipmentId,
      if (customs != null) 'customs': customs!.toJson(),
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

/// ข้อมูลจากใบขนสินค้าขาเข้า (1 ใบต่อ 1 ผู้ส่ง / 1 IMP) กรอกเป็นยอดรวมตามใบขน
class ImportCustoms {
  final String declarationNo;
  final DateTime? declarationDate;
  final double cifValue; // ราคา CIF (บาท)
  final double freightValue; // ค่าเฟรท F (บาท)
  final double importDuty; // อากรขาเข้า (บาท)
  final double vat; // ภาษีมูลค่าเพิ่ม (ยอดรวม)

  ImportCustoms({
    required this.declarationNo,
    this.declarationDate,
    required this.cifValue,
    required this.freightValue,
    required this.importDuty,
    required this.vat,
  });

  /// แยก VAT เป็น VAT ค่าของ / VAT ค่าเฟรท ตามสัดส่วน ค่าเฟรท / (CIF + อากร) เหมือน backend
  ({double goods, double freight}) splitVAT() {
    final base = cifValue + importDuty;
    double freight = 0;
    if (base > 0 && freightValue > 0) {
      freight = (vat * freightValue / base * 100).roundToDouble() / 100;
    }
    return (goods: ((vat - freight) * 100).roundToDouble() / 100, freight: freight);
  }

  factory ImportCustoms.fromJson(Map<String, dynamic> json) {
    return ImportCustoms(
      declarationNo: json['declarationNo'] ?? '',
      declarationDate: json['declarationDate'] != null
          ? DateTime.tryParse(json['declarationDate'])?.toLocal()
          : null,
      cifValue: (json['cifValue'] ?? 0).toDouble(),
      freightValue: (json['freightValue'] ?? 0).toDouble(),
      importDuty: (json['importDuty'] ?? 0).toDouble(),
      vat: (json['vat'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'declarationNo': declarationNo,
      if (declarationDate != null) 'declarationDate': declarationDate!.toUtc().toIso8601String(),
      'cifValue': cifValue,
      'freightValue': freightValue,
      'importDuty': importDuty,
      'vat': vat,
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
  final int piecesPerBox;
  final double boxWidth;
  final double boxLength;
  final double boxHeight;
  final double cbm;
  final bool cbmManual;
  final double shippingCostPerUnit;
  final double dutyPerUnit;
  final double commission;
  final bool commissionPaid;
  final double costPerUnitBeforeVAT;
  final double goodsVATPerUnit;
  final double freightVATPerUnit;
  final double vatPerUnit;
  final double costPerUnitAfterVAT;
  final double totalCost;

  ImportItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.usdPricePerUnit,
    required this.quantity,
    this.piecesPerBox = 1,
    required this.boxWidth,
    required this.boxLength,
    required this.boxHeight,
    required this.cbm,
    this.cbmManual = false,
    required this.shippingCostPerUnit,
    this.dutyPerUnit = 0,
    required this.commission,
    this.commissionPaid = false,
    required this.costPerUnitBeforeVAT,
    this.goodsVATPerUnit = 0,
    this.freightVATPerUnit = 0,
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
      piecesPerBox: json['piecesPerBox'] ?? 1,
      boxWidth: (json['boxWidth'] ?? 0).toDouble(),
      boxLength: (json['boxLength'] ?? 0).toDouble(),
      boxHeight: (json['boxHeight'] ?? 0).toDouble(),
      cbm: (json['cbm'] ?? 0).toDouble(),
      cbmManual: json['cbmManual'] ?? false,
      shippingCostPerUnit: (json['shippingCostPerUnit'] ?? 0).toDouble(),
      dutyPerUnit: (json['dutyPerUnit'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      commissionPaid: json['commissionPaid'] ?? false,
      costPerUnitBeforeVAT: (json['costPerUnitBeforeVAT'] ?? 0).toDouble(),
      goodsVATPerUnit: (json['goodsVATPerUnit'] ?? 0).toDouble(),
      freightVATPerUnit: (json['freightVATPerUnit'] ?? 0).toDouble(),
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
      'piecesPerBox': piecesPerBox,
      'boxWidth': boxWidth,
      'boxLength': boxLength,
      'boxHeight': boxHeight,
      'cbm': cbm,
      'cbmManual': cbmManual,
      'shippingCostPerUnit': shippingCostPerUnit,
      'dutyPerUnit': dutyPerUnit,
      'commission': commission,
      'commissionPaid': commissionPaid,
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
    int? piecesPerBox,
    double? boxWidth,
    double? boxLength,
    double? boxHeight,
    double? cbm,
    bool? cbmManual,
    double? shippingCostPerUnit,
    double? dutyPerUnit,
    double? commission,
    bool? commissionPaid,
    double? costPerUnitBeforeVAT,
    double? goodsVATPerUnit,
    double? freightVATPerUnit,
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
      piecesPerBox: piecesPerBox ?? this.piecesPerBox,
      boxWidth: boxWidth ?? this.boxWidth,
      boxLength: boxLength ?? this.boxLength,
      boxHeight: boxHeight ?? this.boxHeight,
      cbm: cbm ?? this.cbm,
      cbmManual: cbmManual ?? this.cbmManual,
      shippingCostPerUnit: shippingCostPerUnit ?? this.shippingCostPerUnit,
      dutyPerUnit: dutyPerUnit ?? this.dutyPerUnit,
      commission: commission ?? this.commission,
      commissionPaid: commissionPaid ?? this.commissionPaid,
      costPerUnitBeforeVAT: costPerUnitBeforeVAT ?? this.costPerUnitBeforeVAT,
      goodsVATPerUnit: goodsVATPerUnit ?? this.goodsVATPerUnit,
      freightVATPerUnit: freightVATPerUnit ?? this.freightVATPerUnit,
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
  final String? fclShipmentId;
  final ImportCustoms? customs;
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
    this.fclShipmentId,
    this.customs,
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
      if (fclShipmentId != null) 'fclShipmentId': fclShipmentId,
      if (customs != null) 'customs': customs!.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      if (notes != null) 'notes': notes,
    };
  }
}
