class ShippingCompany {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShippingCompany({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShippingCompany.fromJson(Map<String, dynamic> json) {
    return ShippingCompany(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
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
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ShippingCompanyRequest {
  final String name;

  ShippingCompanyRequest({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
