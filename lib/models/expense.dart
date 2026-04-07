class Expense {
  final String id;
  final String category;
  final String description;
  final double amount;
  final DateTime expenseDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      expenseDate: json['expenseDate'] != null
          ? DateTime.parse(json['expenseDate'])
          : DateTime.now(),
      notes: json['notes'] ?? '',
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
      'category': category,
      'description': description,
      'amount': amount,
      'expenseDate': expenseDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ExpenseRequest {
  final String category;
  final String description;
  final double amount;
  final String expenseDate;
  final String notes;

  ExpenseRequest({
    required this.category,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'amount': amount,
      'expenseDate': expenseDate,
      'notes': notes,
    };
  }
}
