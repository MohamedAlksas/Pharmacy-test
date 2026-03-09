class MaterialModel {
  final String id;
  final String name;
  final String sku;
  final String lot;
  final String location;
  final int quantity;
  final String expiryDate;
  final String category;
  final DateTime createdAt;

  MaterialModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.lot,
    required this.location,
    required this.quantity,
    required this.expiryDate,
    required this.category,
    required this.createdAt,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      name: json['name'],
      sku: json['sku'],
      lot: json['lot'],
      location: json['location'],
      quantity: json['qty'],
      expiryDate: json['expiry'],
      category: json['cat'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'lot': lot,
      'location': location,
      'qty': quantity,
      'expiry': expiryDate,
      'cat': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}