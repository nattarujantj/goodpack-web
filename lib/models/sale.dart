
import 'bank_account.dart';

class Sale {
  final String id;
  final String saleCode;
  final String? quotationCode;
  final DateTime saleDate;
  final String customerId;
  final String customerName;
  final String? contactName;
  final String? customerCode;
  final String? taxId;
  final String? address;
  final String? phone;
  final List<SaleItem> items;
  final bool isVAT;
  final String vatType; // "exclusive" (VAT นอก) or "inclusive" (VAT ใน)
  final double shippingCost;
  final PaymentInfo payment;
  final WarehouseInfo warehouse;
  final String? notes;
  final String? bankAccountId;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.saleCode,
    this.quotationCode,
    required this.saleDate,
    required this.customerId,
    required this.customerName,
    this.contactName,
    this.customerCode,
    this.taxId,
    this.address,
    this.phone,
    required this.items,
    required this.isVAT,
    this.vatType = 'exclusive',
    required this.shippingCost,
    required this.payment,
    required this.warehouse,
    this.notes,
    this.bankAccountId,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      saleCode: json['saleCode'],
      quotationCode: json['quotationCode'],
      saleDate: DateTime.parse(json['saleDate']),
      customerId: json['customerId'],
      customerName: json['customerName'],
      contactName: json['contactName'],
      customerCode: json['customerCode'],
      taxId: json['taxId'],
      address: json['address'],
      phone: json['phone'],
      items: (json['items'] as List)
          .map((item) => SaleItem.fromJson(item))
          .toList(),
      isVAT: json['isVAT'],
      vatType: json['vatType'] ?? 'exclusive',
      shippingCost: (json['shippingCost'] ?? 0.0).toDouble(),
      payment: PaymentInfo.fromJson(json['payment']),
      warehouse: WarehouseInfo.fromJson(json['warehouse']),
      notes: json['notes'],
      bankAccountId: json['bankAccountId'],
      bankName: json['bankName'],
      bankAccountName: json['bankAccountName'],
      bankAccountNumber: json['bankAccountNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleCode': saleCode,
      'quotationCode': quotationCode,
      'saleDate': saleDate.toIso8601String(), // ไม่แปลง UTC เพราะเป็น business date
      'customerId': customerId,
      'customerName': customerName,
      'contactName': contactName,
      'customerCode': customerCode,
      'taxId': taxId,
      'address': address,
      'phone': phone,
      'items': items.map((item) => item.toJson()).toList(),
      'isVAT': isVAT,
      'vatType': vatType,
      'shippingCost': shippingCost,
      'payment': payment.toJson(),
      'warehouse': warehouse.toJson(),
      'notes': notes,
      'bankAccountId': bankAccountId,
      'bankName': bankName,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Sale copyWith({
    String? id,
    String? saleCode,
    String? quotationCode,
    DateTime? saleDate,
    String? customerId,
    String? customerName,
    String? contactName,
    String? customerCode,
    String? taxId,
    String? address,
    String? phone,
    List<SaleItem>? items,
    bool? isVAT,
    String? vatType,
    double? shippingCost,
    PaymentInfo? payment,
    WarehouseInfo? warehouse,
    String? notes,
    String? bankAccountId,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      saleCode: saleCode ?? this.saleCode,
      quotationCode: quotationCode ?? this.quotationCode,
      saleDate: saleDate ?? this.saleDate,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      contactName: contactName ?? this.contactName,
      customerCode: customerCode ?? this.customerCode,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      items: items ?? this.items,
      isVAT: isVAT ?? this.isVAT,
      vatType: vatType ?? this.vatType,
      shippingCost: shippingCost ?? this.shippingCost,
      payment: payment ?? this.payment,
      warehouse: warehouse ?? this.warehouse,
      notes: notes ?? this.notes,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SaleItem {
  final String productId;
  final String productName;
  final String productCode;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId'],
      productName: json['productName'],
      productCode: json['productCode'],
      quantity: json['quantity'],
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

class SaleRequest {
  final DateTime saleDate;
  final String customerId;
  final List<SaleItem> items;
  final bool isVAT;
  final String vatType; // "exclusive" (VAT นอก) or "inclusive" (VAT ใน)
  final double shippingCost;
  final PaymentInfo payment;
  final WarehouseInfo warehouse;
  final String? notes;
  final String? quotationCode;
  final String? bankAccountId;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;

  SaleRequest({
    required this.saleDate,
    required this.customerId,
    required this.items,
    required this.isVAT,
    this.vatType = 'exclusive',
    required this.shippingCost,
    required this.payment,
    required this.warehouse,
    this.notes,
    this.quotationCode,
    this.bankAccountId,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'saleDate': saleDate.toIso8601String(), // ไม่แปลง UTC เพราะเป็น business date
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'isVAT': isVAT,
      'vatType': vatType,
      'shippingCost': shippingCost,
      'payment': payment.toJson(),
      'warehouse': warehouse.toJson(),
      'notes': notes,
      'quotationCode': quotationCode,
      'bankAccountId': bankAccountId,
      'bankName': bankName,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
    };
  }
}

class PaymentInfo {
  final bool isPaid;
  final String? paymentMethod;
  final String? ourAccount;
  final BankAccount? ourAccountInfo;
  final String? customerAccount;
  final DateTime? paymentDate;

  PaymentInfo({
    required this.isPaid,
    this.paymentMethod,
    this.ourAccount,
    this.ourAccountInfo,
    this.customerAccount,
    this.paymentDate,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      isPaid: json['isPaid'] as bool,
      paymentMethod: json['paymentMethod'] as String?,
      ourAccount: json['ourAccount'] as String?,
      ourAccountInfo: json['ourAccountInfo'] != null
          ? BankAccount.fromJson(json['ourAccountInfo'] as Map<String, dynamic>)
          : null,
      customerAccount: json['customerAccount'] as String?,
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'ourAccount': ourAccount,
      'ourAccountInfo': ourAccountInfo?.toJson(),
      'customerAccount': customerAccount,
      'paymentDate': paymentDate?.toIso8601String(), // ไม่แปลง UTC
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
      isUpdated: json['isUpdated'] as bool,
      notes: json['notes'] as String?,
      actualShipping: (json['actualShipping'] as num?)?.toDouble() ?? 0.0,
      items: (json['items'] as List<dynamic>?)
              ?.map((itemJson) => WarehouseItem.fromJson(itemJson as Map<String, dynamic>))
              .toList() ??
          [],
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
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      boxes: json['boxes'] as int,
      notes: json['notes'] as String?,
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
