
// QuotationItem represents an item in a quotation
class QuotationItem {
  final String productId;
  final String productName;
  final String productCode;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  QuotationItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
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

// Quotation represents a quotation document
class Quotation {
  final String id;
  final String quotationCode;
  final DateTime quotationDate;
  final String customerId;
  final String customerName;
  final String? contactName;
  final String? customerCode;
  final String? taxId;
  final String? address;
  final String? phone;
  final List<QuotationItem> items;
  final bool isVAT;
  final String vatType; // "exclusive" (VAT นอก) or "inclusive" (VAT ใน)
  final double shippingCost;
  final String? notes;
  final DateTime? validUntil;
  final String status;
  final String? saleCode;
  final String? bankAccountId;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quotation({
    required this.id,
    required this.quotationCode,
    required this.quotationDate,
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
    this.notes,
    this.validUntil,
    required this.status,
    this.saleCode,
    this.bankAccountId,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['_id']?['\$oid'] as String? ?? json['id'] as String? ?? '',
      quotationCode: json['quotationCode'] as String? ?? '',
      quotationDate: DateTime.parse(json['quotationDate'] as String? ?? DateTime.now().toIso8601String()),
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      contactName: json['contactName'] as String?,
      customerCode: json['customerCode'] as String?,
      taxId: json['taxId'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => QuotationItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      isVAT: json['isVAT'] as bool? ?? false,
      vatType: json['vatType'] as String? ?? 'exclusive',
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      validUntil: json['validUntil'] != null 
          ? DateTime.parse(json['validUntil'] as String) 
          : null,
      status: json['status'] as String? ?? 'draft',
      saleCode: json['saleCode'] as String?,
      bankAccountId: json['bankAccountId'] as String?,
      bankName: json['bankName'] as String?,
      bankAccountName: json['bankAccountName'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quotationDate': quotationDate.toIso8601String(),
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'isVAT': isVAT,
      'vatType': vatType,
      'shippingCost': shippingCost,
      'notes': notes,
      'validUntil': validUntil?.toIso8601String(),
      'status': status,
      'bankAccountId': bankAccountId,
      'bankName': bankName,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
    };
  }

  Quotation copyWith({
    String? id,
    String? quotationCode,
    DateTime? quotationDate,
    String? customerId,
    String? customerName,
    String? contactName,
    String? customerCode,
    String? taxId,
    String? address,
    String? phone,
    List<QuotationItem>? items,
    bool? isVAT,
    String? vatType,
    double? shippingCost,
    String? notes,
    DateTime? validUntil,
    String? status,
    String? saleCode,
    String? bankAccountId,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      quotationCode: quotationCode ?? this.quotationCode,
      quotationDate: quotationDate ?? this.quotationDate,
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
      notes: notes ?? this.notes,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
      saleCode: saleCode ?? this.saleCode,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double calculateGrandTotal() {
    final totalBeforeVAT = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    double totalVAT = 0.0;
    double grandTotal = 0.0;
    
    if (isVAT) {
      if (vatType == 'inclusive') {
        // VAT ใน: ราคารวม VAT แล้ว ต้องถอด VAT ออก
        // ราคาก่อน VAT = ราคารวม / 1.07
        // VAT = ราคารวม - ราคาก่อน VAT
        totalVAT = totalBeforeVAT - (totalBeforeVAT / 1.07);
        grandTotal = totalBeforeVAT; // ราคาที่กรอกคือราคารวม VAT แล้ว
      } else {
        // VAT นอก (exclusive): ราคา + VAT 7%
        totalVAT = totalBeforeVAT * 0.07;
        grandTotal = totalBeforeVAT + totalVAT;
      }
    } else {
      grandTotal = totalBeforeVAT;
    }
    
    return grandTotal + shippingCost;
  }

  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'ร่าง';
      case 'sent':
        return 'ส่งแล้ว';
      case 'accepted':
        return 'ยอมรับ';
      case 'rejected':
        return 'ปฏิเสธ';
      case 'expired':
        return 'หมดอายุ';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'draft':
        return 'orange';
      case 'sent':
        return 'blue';
      case 'accepted':
        return 'green';
      case 'rejected':
        return 'red';
      case 'expired':
        return 'grey';
      default:
        return 'grey';
    }
  }
}

// QuotationRequest represents the request body for creating/updating a quotation
class QuotationRequest {
  final DateTime quotationDate;
  final String customerId;
  final List<QuotationItem> items;
  final bool isVAT;
  final String vatType; // "exclusive" or "inclusive"
  final double shippingCost;
  final String? notes;
  final DateTime? validUntil;
  final String status;
  final String? bankAccountId;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;

  QuotationRequest({
    required this.quotationDate,
    required this.customerId,
    required this.items,
    required this.isVAT,
    this.vatType = 'exclusive',
    required this.shippingCost,
    this.notes,
    this.validUntil,
    required this.status,
    this.bankAccountId,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'quotationDate': quotationDate.toIso8601String(),
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'isVAT': isVAT,
      'vatType': vatType,
      'shippingCost': shippingCost,
      'notes': notes,
      'validUntil': validUntil?.toIso8601String(),
      'status': status,
      'bankAccountId': bankAccountId,
      'bankName': bankName,
      'bankAccountName': bankAccountName,
      'bankAccountNumber': bankAccountNumber,
    };
  }
}
