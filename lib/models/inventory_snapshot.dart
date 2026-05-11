class ProductSnapshotItem {
  final String productId;
  final String skuId;
  final String code;
  final String name;
  final String category;
  final String color;
  final String size;
  final int vatRemaining;
  final int nonVATRemaining;
  final int actualStock;

  const ProductSnapshotItem({
    required this.productId,
    required this.skuId,
    required this.code,
    required this.name,
    required this.category,
    required this.color,
    required this.size,
    required this.vatRemaining,
    required this.nonVATRemaining,
    required this.actualStock,
  });

  factory ProductSnapshotItem.fromJson(Map<String, dynamic> json) {
    return ProductSnapshotItem(
      productId: json['productId'] ?? '',
      skuId: json['skuId'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      color: json['color'] ?? '',
      size: json['size'] ?? '',
      vatRemaining: json['vatRemaining'] ?? 0,
      nonVATRemaining: json['nonVATRemaining'] ?? 0,
      actualStock: json['actualStock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'skuId': skuId,
        'code': code,
        'name': name,
        'category': category,
        'color': color,
        'size': size,
        'vatRemaining': vatRemaining,
        'nonVATRemaining': nonVATRemaining,
        'actualStock': actualStock,
      };

  ProductSnapshotItem copyWith({
    int? vatRemaining,
    int? nonVATRemaining,
    int? actualStock,
  }) {
    return ProductSnapshotItem(
      productId: productId,
      skuId: skuId,
      code: code,
      name: name,
      category: category,
      color: color,
      size: size,
      vatRemaining: vatRemaining ?? this.vatRemaining,
      nonVATRemaining: nonVATRemaining ?? this.nonVATRemaining,
      actualStock: actualStock ?? this.actualStock,
    );
  }
}

class InventorySnapshot {
  final String id;
  final int month;
  final int year;
  final DateTime snapshotDate;
  final String createdBy;
  final bool isManual;
  final List<ProductSnapshotItem> products;
  final int totalProducts;
  final int totalVATStock;
  final int totalNonVATStock;
  final int totalActualStock;

  const InventorySnapshot({
    required this.id,
    required this.month,
    required this.year,
    required this.snapshotDate,
    required this.createdBy,
    required this.isManual,
    required this.products,
    required this.totalProducts,
    required this.totalVATStock,
    required this.totalNonVATStock,
    required this.totalActualStock,
  });

  factory InventorySnapshot.fromJson(Map<String, dynamic> json) {
    return InventorySnapshot(
      id: json['id'] ?? '',
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      snapshotDate: json['snapshotDate'] != null
          ? DateTime.parse(json['snapshotDate']).toLocal()
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      isManual: json['isManual'] ?? false,
      products: (json['products'] as List<dynamic>? ?? [])
          .map((p) => ProductSnapshotItem.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalProducts: json['totalProducts'] ?? 0,
      totalVATStock: json['totalVATStock'] ?? 0,
      totalNonVATStock: json['totalNonVATStock'] ?? 0,
      totalActualStock: json['totalActualStock'] ?? 0,
    );
  }
}
