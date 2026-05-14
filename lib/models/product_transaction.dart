class ProductTransactionItem {
  final String id;
  final String documentCode;
  final DateTime date;
  final String partnerName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double totalVAT;
  final double grandTotal;

  const ProductTransactionItem({
    required this.id,
    required this.documentCode,
    required this.date,
    required this.partnerName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.totalVAT,
    required this.grandTotal,
  });

  factory ProductTransactionItem.fromJson(Map<String, dynamic> json) {
    return ProductTransactionItem(
      id: json['id'] as String,
      documentCode: json['documentCode'] as String,
      date: DateTime.parse(json['date'] as String),
      partnerName: json['partnerName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      totalVAT: (json['totalVAT'] as num).toDouble(),
      grandTotal: (json['grandTotal'] as num).toDouble(),
    );
  }
}

class ProductTransactionPage {
  final List<ProductTransactionItem> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const ProductTransactionPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ProductTransactionPage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List<dynamic>? ?? [];
    return ProductTransactionPage(
      data: rawData
          .map((e) => ProductTransactionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );
  }
}
