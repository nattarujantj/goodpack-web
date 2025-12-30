
// PriceInfo represents price information for VAT and Non-VAT
class PriceInfo {
  final double latest;
  final double min;
  final double max;
  final double average;
  final double averageYTD;
  final double averageMTD;
  
  // สำหรับคำนวณ Weighted Average
  final int totalQuantity;
  final double totalAmount;
  
  // สำหรับคำนวณ Weighted Average YTD
  final int ytdYear;
  final int ytdQuantity;
  final double ytdTotalAmount;
  
  // สำหรับคำนวณ Weighted Average MTD
  final int mtdMonth;
  final int mtdYear;
  final int mtdQuantity;
  final double mtdTotalAmount;

  PriceInfo({
    required this.latest,
    required this.min,
    required this.max,
    required this.average,
    required this.averageYTD,
    required this.averageMTD,
    required this.totalQuantity,
    required this.totalAmount,
    required this.ytdYear,
    required this.ytdQuantity,
    required this.ytdTotalAmount,
    required this.mtdMonth,
    required this.mtdYear,
    required this.mtdQuantity,
    required this.mtdTotalAmount,
  });

  factory PriceInfo.fromJson(Map<String, dynamic> json) {
    return PriceInfo(
      latest: (json['latest'] as num?)?.toDouble() ?? 0.0,
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 0.0,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      averageYTD: (json['averageYTD'] as num?)?.toDouble() ?? 0.0,
      averageMTD: (json['averageMTD'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: json['totalQuantity'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      ytdYear: json['ytdYear'] as int? ?? 0,
      ytdQuantity: json['ytdQuantity'] as int? ?? 0,
      ytdTotalAmount: (json['ytdTotalAmount'] as num?)?.toDouble() ?? 0.0,
      mtdMonth: json['mtdMonth'] as int? ?? 0,
      mtdYear: json['mtdYear'] as int? ?? 0,
      mtdQuantity: json['mtdQuantity'] as int? ?? 0,
      mtdTotalAmount: (json['mtdTotalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest': latest,
      'min': min,
      'max': max,
      'average': average,
      'averageYTD': averageYTD,
      'averageMTD': averageMTD,
      'totalQuantity': totalQuantity,
      'totalAmount': totalAmount,
      'ytdYear': ytdYear,
      'ytdQuantity': ytdQuantity,
      'ytdTotalAmount': ytdTotalAmount,
      'mtdMonth': mtdMonth,
      'mtdYear': mtdYear,
      'mtdQuantity': mtdQuantity,
      'mtdTotalAmount': mtdTotalAmount,
    };
  }
}

// TierPrice represents tier pricing for sales
class TierPrice {
  final int minQuantity;
  final int? maxQuantity;
  final PriceInfo price;
  final double wholesalePrice; // ราคาขายส่ง (บาท)

  TierPrice({
    required this.minQuantity,
    this.maxQuantity,
    required this.price,
    required this.wholesalePrice,
  });

  factory TierPrice.fromJson(Map<String, dynamic> json) {
    return TierPrice(
      minQuantity: json['minQuantity'] as int? ?? 0,
      maxQuantity: json['maxQuantity'] as int?,
      price: PriceInfo.fromJson(json['price'] as Map<String, dynamic>? ?? {}),
      wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'price': price.toJson(),
      'wholesalePrice': wholesalePrice,
    };
  }

  String get quantityRange {
    if (maxQuantity == null) {
      return '${minQuantity}+ ชิ้น';
    }
    return '$minQuantity-$maxQuantity ชิ้น';
  }
}

// Price represents all pricing information
class Price {
  final PriceInfo purchaseVAT;
  final PriceInfo purchaseNonVAT;
  final PriceInfo saleVAT;
  final PriceInfo saleNonVAT;
  final List<TierPrice> salesTiers;

  Price({
    required this.purchaseVAT,
    required this.purchaseNonVAT,
    required this.saleVAT,
    required this.saleNonVAT,
    required this.salesTiers,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      purchaseVAT: PriceInfo.fromJson(json['purchaseVAT'] as Map<String, dynamic>? ?? {}),
      purchaseNonVAT: PriceInfo.fromJson(json['purchaseNonVAT'] as Map<String, dynamic>? ?? {}),
      saleVAT: PriceInfo.fromJson(json['saleVAT'] as Map<String, dynamic>? ?? {}),
      saleNonVAT: PriceInfo.fromJson(json['saleNonVAT'] as Map<String, dynamic>? ?? {}),
      salesTiers: (json['salesTiers'] as List?)
          ?.map((tier) => TierPrice.fromJson(tier as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purchaseVAT': purchaseVAT.toJson(),
      'purchaseNonVAT': purchaseNonVAT.toJson(),
      'saleVAT': saleVAT.toJson(),
      'saleNonVAT': saleNonVAT.toJson(),
      'salesTiers': salesTiers.map((tier) => tier.toJson()).toList(),
    };
  }

  double get displayPrice {
    if (saleVAT.latest > 0) {
      return saleVAT.latest;
    }
    return saleNonVAT.latest;
  }
}

// StockInfo represents stock information for VAT and Non-VAT
class StockInfo {
  final int initialStock; // สินค้ายกยอดมา
  final int purchased;
  final int sold;
  final int remaining;

  StockInfo({
    required this.initialStock,
    required this.purchased,
    required this.sold,
    required this.remaining,
  });

  factory StockInfo.fromJson(Map<String, dynamic> json) {
    return StockInfo(
      initialStock: json['initialStock'] as int? ?? 0,
      purchased: json['purchased'] as int? ?? 0,
      sold: json['sold'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'initialStock': initialStock,
      'purchased': purchased,
      'sold': sold,
      'remaining': remaining,
    };
  }
}

// Stock represents all stock information
class Stock {
  final StockInfo vat;
  final StockInfo nonVAT;
  final int actualStockInitial; // ยกยอด ActualStock
  final int actualStock;

  Stock({
    required this.vat,
    required this.nonVAT,
    required this.actualStockInitial,
    required this.actualStock,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      vat: StockInfo.fromJson(json['vat'] as Map<String, dynamic>? ?? {}),
      nonVAT: StockInfo.fromJson(json['nonVAT'] as Map<String, dynamic>? ?? {}),
      actualStockInitial: json['actualStockInitial'] as int? ?? 0,
      actualStock: json['actualStock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vat': vat.toJson(),
      'nonVAT': nonVAT.toJson(),
      'actualStockInitial': actualStockInitial,
      'actualStock': actualStock,
    };
  }

  int get totalStock => actualStock;
}

class Product {
  final String id;
  final String skuId;
  final String code;
  final String name;
  final String description;
  final String color;
  final String size;
  final String category;
  final String qrData;
  final String? imageUrl;
  final int quantityPerPack; // จำนวน/ลัง(แพ็ค)
  final Price price;
  final Stock stock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.skuId,
    required this.code,
    required this.name,
    required this.description,
    required this.color,
    required this.size,
    required this.category,
    required this.qrData,
    this.imageUrl,
    this.quantityPerPack = 0,
    required this.price,
    required this.stock,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for JSON deserialization
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      skuId: json['skuId'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? '',
      size: json['size'] as String? ?? '',
      category: json['category'] as String? ?? '',
      qrData: json['qrData'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      quantityPerPack: (json['quantityPerPack'] as num?)?.toInt() ?? 0,
      price: Price.fromJson(json['price'] as Map<String, dynamic>? ?? {}),
      stock: Stock.fromJson(json['stock'] as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skuId': skuId,
      'code': code,
      'name': name,
      'description': description,
      'color': color,
      'size': size,
      'category': category,
      'qrData': qrData,
      'imageUrl': imageUrl,
      'quantityPerPack': quantityPerPack,
      'price': price.toJson(),
      'stock': stock.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? skuId,
    String? code,
    String? name,
    String? description,
    String? color,
    String? size,
    String? category,
    String? qrData,
    String? imageUrl,
    int? quantityPerPack,
    Price? price,
    Stock? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      skuId: skuId ?? this.skuId,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      size: size ?? this.size,
      category: category ?? this.category,
      qrData: qrData ?? this.qrData,
      imageUrl: imageUrl, // Allow null values
      quantityPerPack: quantityPerPack ?? this.quantityPerPack,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to check if product is low stock
  bool get isLowStock => stock.actualStock <= 10;

  // Helper method to get formatted price
  String get formattedPrice => '฿${price.displayPrice.toStringAsFixed(2)}';

  

  // Helper method to get total stock
  int get totalStock => stock.actualStock;

  // Helper method to calculate pack remaining
  String get packRemainingText {
    if (quantityPerPack <= 0) {
      return '-';
    }
    final packs = stock.actualStock ~/ quantityPerPack;
    final remainder = stock.actualStock % quantityPerPack;
    if (remainder == 0) {
      return '$packs ลัง(แพ็ค)';
    } else {
      return '$packs ลัง(แพ็ค) เศษ $remainder';
    }
  }

  @override
  String toString() {
    return 'Product{id: $id, skuId: $skuId, name: $name, price: ${price.displayPrice}, stock: ${stock.actualStock}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
