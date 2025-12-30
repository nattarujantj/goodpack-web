class CustomerBankAccount {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final bool isDefault;

  CustomerBankAccount({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.isDefault = false,
  });

  factory CustomerBankAccount.fromJson(Map<String, dynamic> json) {
    return CustomerBankAccount(
      bankName: json['bankName'] ?? '',
      accountName: json['accountName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'isDefault': isDefault,
    };
  }

  CustomerBankAccount copyWith({
    String? bankName,
    String? accountName,
    String? accountNumber,
    bool? isDefault,
  }) {
    return CustomerBankAccount(
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get displayName => '$bankName - $accountName ($accountNumber)';

  @override
  String toString() => '$bankName $accountName $accountNumber${isDefault ? ' - หลัก' : ''}';
}
