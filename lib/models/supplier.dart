class Supplier {
  final String id;
  final String supplierCode; // S-0001, S-0002, etc.
  final String companyName;
  final String contactName;
  final String taxId;
  final String phone;
  final String address;
  final String contactMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.supplierCode,
    required this.companyName,
    required this.contactName,
    required this.taxId,
    required this.phone,
    required this.address,
    required this.contactMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? '',
      supplierCode: json['supplierCode'] ?? '',
      companyName: json['companyName'] ?? '',
      contactName: json['contactName'] ?? '',
      taxId: json['taxId'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      contactMethod: json['contactMethod'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplierCode': supplierCode,
      'companyName': companyName,
      'contactName': contactName,
      'taxId': taxId,
      'phone': phone,
      'address': address,
      'contactMethod': contactMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Supplier copyWith({
    String? id,
    String? supplierCode,
    String? companyName,
    String? contactName,
    String? taxId,
    String? phone,
    String? address,
    String? contactMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      supplierCode: supplierCode ?? this.supplierCode,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      taxId: taxId ?? this.taxId,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      contactMethod: contactMethod ?? this.contactMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Supplier(id: $id, supplierCode: $supplierCode, companyName: $companyName, contactName: $contactName, taxId: $taxId, phone: $phone, address: $address, contactMethod: $contactMethod)';
  }
}

class SupplierRequest {
  final String companyName;
  final String contactName;
  final String taxId;
  final String phone;
  final String address;
  final String contactMethod;

  SupplierRequest({
    required this.companyName,
    required this.contactName,
    required this.taxId,
    required this.phone,
    required this.address,
    required this.contactMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'contactName': contactName,
      'taxId': taxId,
      'phone': phone,
      'address': address,
      'contactMethod': contactMethod,
    };
  }
}

