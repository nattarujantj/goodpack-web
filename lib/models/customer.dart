import 'contact.dart';
import 'customer_bank_account.dart';

class Customer {
  final String id;
  final String customerCode; // C-0001, C-0002, etc.
  final String companyName;
  final String contactName; // Legacy: primary contact name
  final String taxId;
  final String phone; // Legacy: primary phone
  final String address;
  final String contactMethod;
  final List<Contact> contacts; // รายการผู้ติดต่อทั้งหมด
  final List<CustomerBankAccount> bankAccounts; // รายการบัญชีธนาคาร
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.customerCode,
    required this.companyName,
    required this.contactName,
    required this.taxId,
    required this.phone,
    required this.address,
    required this.contactMethod,
    this.contacts = const [],
    this.bankAccounts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // ดึงผู้ติดต่อหลัก (default)
  Contact? get primaryContact {
    if (contacts.isEmpty) {
      // Fallback to legacy fields
      if (contactName.isNotEmpty) {
        return Contact(name: contactName, phone: phone, isDefault: true);
      }
      return null;
    }
    return contacts.firstWhere(
      (c) => c.isDefault,
      orElse: () => contacts.first,
    );
  }

  // ดึงบัญชีหลัก (default)
  CustomerBankAccount? get primaryBankAccount {
    if (bankAccounts.isEmpty) return null;
    return bankAccounts.firstWhere(
      (b) => b.isDefault,
      orElse: () => bankAccounts.first,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    List<Contact> contactList = [];
    if (json['contacts'] != null) {
      contactList = (json['contacts'] as List)
          .map((c) => Contact.fromJson(c))
          .toList();
    }
    
    List<CustomerBankAccount> bankAccountList = [];
    if (json['bankAccounts'] != null) {
      bankAccountList = (json['bankAccounts'] as List)
          .map((b) => CustomerBankAccount.fromJson(b))
          .toList();
    }
    
    return Customer(
      id: json['id'] ?? '',
      customerCode: json['customerCode'] ?? '',
      companyName: json['companyName'] ?? '',
      contactName: json['contactName'] ?? '',
      taxId: json['taxId'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      contactMethod: json['contactMethod'] ?? '',
      contacts: contactList,
      bankAccounts: bankAccountList,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerCode': customerCode,
      'companyName': companyName,
      'contactName': contactName,
      'taxId': taxId,
      'phone': phone,
      'address': address,
      'contactMethod': contactMethod,
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'bankAccounts': bankAccounts.map((b) => b.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? customerCode,
    String? companyName,
    String? contactName,
    String? taxId,
    String? phone,
    String? address,
    String? contactMethod,
    List<Contact>? contacts,
    List<CustomerBankAccount>? bankAccounts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      taxId: taxId ?? this.taxId,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      contactMethod: contactMethod ?? this.contactMethod,
      contacts: contacts ?? this.contacts,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, customerCode: $customerCode, companyName: $companyName, contactName: $contactName, taxId: $taxId, phone: $phone, address: $address, contactMethod: $contactMethod, contacts: ${contacts.length}, bankAccounts: ${bankAccounts.length})';
  }
}

class CustomerRequest {
  final String companyName;
  final String contactName;
  final String taxId;
  final String phone;
  final String address;
  final String contactMethod;
  final List<Contact> contacts;
  final List<CustomerBankAccount> bankAccounts;

  CustomerRequest({
    required this.companyName,
    required this.contactName,
    required this.taxId,
    required this.phone,
    required this.address,
    required this.contactMethod,
    this.contacts = const [],
    this.bankAccounts = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'contactName': contactName,
      'taxId': taxId,
      'phone': phone,
      'address': address,
      'contactMethod': contactMethod,
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'bankAccounts': bankAccounts.map((b) => b.toJson()).toList(),
    };
  }
}
