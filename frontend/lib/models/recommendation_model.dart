class RecommendationModel {
  final String id;
  final String name;
  final double price;
  final double? discountPrice;
  final String image;
  final double rating;

  RecommendationModel({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice,
    required this.image,
    required this.rating,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'منتج مقترح',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      discountPrice: json['discount_price'] != null
          ? double.tryParse(json['discount_price'].toString())
          : null,
      image: json['image'] ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
    );
  }
}
