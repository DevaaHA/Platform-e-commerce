class ProductSearchModel {
  final String id;
  final String name;
  final double price;
  final double? discountPrice;
  final String image;
  final double rating;
  final String storeName;

  ProductSearchModel({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice,
    required this.image,
    required this.rating,
    required this.storeName,
  });

  factory ProductSearchModel.fromJson(Map<String, dynamic> json) {
    return ProductSearchModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'منتج بدون عنوان',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      discountPrice: json['discount_price'] != null
          ? double.tryParse(json['discount_price'].toString())
          : null,
      image: json['image'] ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
      storeName: json['store_name'] ?? 'سوق جو',
    );
  }
}
