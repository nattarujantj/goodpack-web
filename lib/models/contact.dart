class Contact {
  final String name;
  final String phone;
  final bool isDefault;

  Contact({
    required this.name,
    required this.phone,
    this.isDefault = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'isDefault': isDefault,
    };
  }

  Contact copyWith({
    String? name,
    String? phone,
    bool? isDefault,
  }) {
    return Contact(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() => '$name ($phone)${isDefault ? ' - หลัก' : ''}';
}

