class ProductModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String description;
  final double price;
  final int stockQuantity;
  final String imageUrl;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.imageUrl,
    required this.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar'] ?? json['name'] ?? '',
      nameEn: json['name_en'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stockQuantity:
          int.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0,
      imageUrl: json['image'] ?? json['image_url'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }
}
