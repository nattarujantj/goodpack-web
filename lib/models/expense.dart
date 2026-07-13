class ExpenseAttachment {
  final String id;
  final String fileName;
  final String fileUrl;
  final String fileType; // "pdf" or "image"
  final int size;
  final DateTime uploadedAt;

  ExpenseAttachment({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    this.size = 0,
    required this.uploadedAt,
  });

  bool get isPdf => fileType == 'pdf';
  bool get isImage => fileType == 'image';

  factory ExpenseAttachment.fromJson(Map<String, dynamic> json) {
    return ExpenseAttachment(
      id: json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? '',
      size: (json['size'] ?? 0) is int
          ? (json['size'] ?? 0)
          : (json['size'] ?? 0).toInt(),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class Expense {
  final String id;
  final String category;
  final String description;
  final double amount;
  final DateTime expenseDate;
  final String notes;
  final List<ExpenseAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.notes = '',
    this.attachments = const [],
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
          ? DateTime.parse(json['expenseDate']).toLocal()
          : DateTime.now(),
      notes: json['notes'] ?? '',
      attachments: json['attachments'] != null && json['attachments'] is List
          ? (json['attachments'] as List)
              .map((a) => ExpenseAttachment.fromJson(a))
              .toList()
          : const [],
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
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? category,
    String? description,
    double? amount,
    DateTime? expenseDate,
    String? notes,
    List<ExpenseAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
