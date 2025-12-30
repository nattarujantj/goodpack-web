class Purchase {
  final String id;
  final String purchaseCode;
  final String? invoiceNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime purchaseDate;
  final String supplierId;
  final String supplierName;
  final String? contactName;
  final String? supplierCode;
  final String? taxId;
  final String? address;
  final String? phone;
  final String? notes;
  final List<PurchaseItem> items;
  final bool isVAT;
  final double shippingCost;
  final PaymentInfo payment;
  final WarehouseInfo warehouse;
  final double totalAmount;
  final double totalVAT;
  final double grandTotal;

  Purchase({
    required this.id,
    required this.purchaseCode,
    this.invoiceNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.purchaseDate,
    required this.supplierId,
    required this.supplierName,
    this.contactName,
    this.supplierCode,
    this.taxId,
    this.address,
    this.phone,
    this.notes,
    required this.items,
    required this.isVAT,
    required this.shippingCost,
    required this.payment,
    required this.warehouse,
    required this.totalAmount,
    required this.totalVAT,
    required this.grandTotal,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] ?? '',
      purchaseCode: json['purchaseCode'] ?? '',
      invoiceNumber: json['invoiceNumber'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      purchaseDate: DateTime.tryParse(json['purchaseDate'] ?? '') ?? DateTime.now(),
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      contactName: json['contactName'],
      supplierCode: json['supplierCode'],
      taxId: json['taxId'],
      address: json['address'],
      phone: json['phone'],
      notes: json['notes'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => PurchaseItem.fromJson(item))
          .toList() ?? [],
      isVAT: json['isVAT'] ?? false,
      shippingCost: (json['shippingCost'] ?? 0.0).toDouble(),
      payment: PaymentInfo.fromJson(json['payment'] ?? {}),
      warehouse: WarehouseInfo.fromJson(json['warehouse'] ?? {}),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      totalVAT: (json['totalVAT'] ?? 0.0).toDouble(),
      grandTotal: (json['grandTotal'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchaseCode': purchaseCode,
      'invoiceNumber': invoiceNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'purchaseDate': purchaseDate.toIso8601String(),
      'supplierId': supplierId,
      'supplierName': supplierName,
      'contactName': contactName,
      'supplierCode': supplierCode,
      'taxId': taxId,
      'address': address,
      'phone': phone,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'isVAT': isVAT,
      'shippingCost': shippingCost,
      'payment': payment.toJson(),
      'warehouse': warehouse.toJson(),
      'totalAmount': totalAmount,
      'totalVAT': totalVAT,
      'grandTotal': grandTotal,
    };
  }

  Purchase copyWith({
    String? id,
    String? purchaseCode,
    String? invoiceNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? purchaseDate,
    String? supplierId,
    String? supplierName,
    String? contactName,
    String? supplierCode,
    String? taxId,
    String? address,
    String? phone,
    String? notes,
    List<PurchaseItem>? items,
    bool? isVAT,
    double? shippingCost,
    PaymentInfo? payment,
    WarehouseInfo? warehouse,
    double? totalAmount,
    double? totalVAT,
    double? grandTotal,
  }) {
    return Purchase(
      id: id ?? this.id,
      purchaseCode: purchaseCode ?? this.purchaseCode,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      contactName: contactName ?? this.contactName,
      supplierCode: supplierCode ?? this.supplierCode,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      isVAT: isVAT ?? this.isVAT,
      shippingCost: shippingCost ?? this.shippingCost,
      payment: payment ?? this.payment,
      warehouse: warehouse ?? this.warehouse,
      totalAmount: totalAmount ?? this.totalAmount,
      totalVAT: totalVAT ?? this.totalVAT,
      grandTotal: grandTotal ?? this.grandTotal,
    );
  }
}

class PurchaseItem {
  final String productId;
  final String productName;
  final String productCode;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  PurchaseItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productCode: json['productCode'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productCode': productCode,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

class PaymentInfo {
  final bool isPaid;
  final String? paymentMethod;
  final String? ourAccount;
  final String? customerAccount;
  final DateTime? paymentDate;

  PaymentInfo({
    required this.isPaid,
    this.paymentMethod,
    this.ourAccount,
    this.customerAccount,
    this.paymentDate,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      isPaid: json['isPaid'] ?? false,
      paymentMethod: json['paymentMethod'],
      ourAccount: json['ourAccount'],
      customerAccount: json['customerAccount'],
      paymentDate: json['paymentDate'] != null 
          ? DateTime.tryParse(json['paymentDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'ourAccount': ourAccount,
      'customerAccount': customerAccount,
      'paymentDate': paymentDate?.toUtc().toIso8601String(),
    };
  }
}

class WarehouseInfo {
  final bool isUpdated;
  final String? notes;
  final double actualShipping;
  final List<WarehouseItem> items;

  WarehouseInfo({
    required this.isUpdated,
    this.notes,
    required this.actualShipping,
    required this.items,
  });

  factory WarehouseInfo.fromJson(Map<String, dynamic> json) {
    return WarehouseInfo(
      isUpdated: json['isUpdated'] ?? false,
      notes: json['notes'],
      actualShipping: (json['actualShipping'] ?? 0.0).toDouble(),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => WarehouseItem.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isUpdated': isUpdated,
      'notes': notes,
      'actualShipping': actualShipping,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class WarehouseItem {
  final String productId;
  final String productName;
  final int quantity;
  final int boxes;
  final String? notes;

  WarehouseItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.boxes,
    this.notes,
  });

  factory WarehouseItem.fromJson(Map<String, dynamic> json) {
    return WarehouseItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      boxes: json['boxes'] ?? 0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'boxes': boxes,
      'notes': notes,
    };
  }
}

class PurchaseRequest {
  final DateTime purchaseDate;
  final String supplierId;
  final String? invoiceNumber;
  final String? notes;
  final List<PurchaseItem> items;
  final bool isVAT;
  final double shippingCost;
  final PaymentInfo payment;
  final WarehouseInfo warehouse;

  PurchaseRequest({
    required this.purchaseDate,
    required this.supplierId,
    this.invoiceNumber,
    this.notes,
    required this.items,
    required this.isVAT,
    required this.shippingCost,
    required this.payment,
    required this.warehouse,
  });

  Map<String, dynamic> toJson() {
    return {
      'purchaseDate': purchaseDate.toUtc().toIso8601String(),
      'supplierId': supplierId,
      'invoiceNumber': invoiceNumber,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'isVAT': isVAT,
      'shippingCost': shippingCost,
      'payment': payment.toJson(),
      'warehouse': warehouse.toJson(),
    };
  }
}
