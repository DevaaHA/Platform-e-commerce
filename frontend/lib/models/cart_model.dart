class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final String storeName;
  final String imageUrl;
  final double unitPrice;
  int quantity;
  final double subtotal;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.storeName,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] ?? 'منتج',
      storeName: json['store_name'] ?? 'متجر سوق جو',
      imageUrl: json['image_url'] ?? '',
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] ?? 1,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}
