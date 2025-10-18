import '../services/config_service.dart';

class BankAccount {
  final String id;
  final String bankName;
  final String bankAccountName;
  final String accountNumber;
  final String? branchName;
  final bool isActive;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.bankAccountName,
    required this.accountNumber,
    this.branchName,
    this.isActive = true,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      bankAccountName: json['name'] as String? ?? '', // แก้ไขจาก 'accountName' เป็น 'name'
      accountNumber: json['accountNumber'] as String? ?? '',
      branchName: json['branchName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'accountName': bankAccountName,
      'accountNumber': accountNumber,
      'branchName': branchName,
      'isActive': isActive,
    };
  }

  BankAccount copyWith({
    String? id,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? branchName,
    bool? isActive,
  }) {
    return BankAccount(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      bankAccountName: accountName ?? this.bankAccountName,
      accountNumber: accountNumber ?? this.accountNumber,
      branchName: branchName ?? this.branchName,
      isActive: isActive ?? this.isActive,
    );
  }

  String get displayName => '$bankAccountName ($accountNumber) - $bankName';
  String get fullDisplayName => '$bankName\n$bankAccountName\n$accountNumber';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankAccount &&
        other.id == id &&
        other.bankName == bankName &&
        other.bankAccountName == bankAccountName &&
        other.accountNumber == accountNumber &&
        other.branchName == branchName &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      bankName,
      bankAccountName,
      accountNumber,
      branchName,
      isActive,
    );
  }
}


// Service สำหรับดึงข้อมูลบัญชีจาก server
class BankAccountService {
  static Future<List<BankAccount>> getBankAccounts() async {
    try {
      // ใช้ ConfigService ที่มีอยู่แล้ว
      final configService = ConfigService();
      await configService.loadConfig();
      
      // แปลง AccountItem เป็น BankAccount
      return configService.accounts.map((account) => BankAccount(
        id: account.id,
        bankName: account.bankName,
        bankAccountName: account.name,
        accountNumber: account.accountNumber,
        isActive: account.isActive,
      )).toList();
    } catch (e) {
      // print('Error loading bank accounts from server: $e');
      // Return empty list if server is not available
      return [];
    }
  }
}
