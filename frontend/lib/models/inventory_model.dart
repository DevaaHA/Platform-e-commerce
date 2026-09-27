class InventoryModel {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final int minimumQuantity;
  final String status;

  InventoryModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.minimumQuantity,
    required this.status,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] ?? 'منتج غير محدد',
      sku: json['sku'] ?? 'N/A',
      quantity: json['quantity'] ?? 0,
      reservedQuantity: json['reserved_quantity'] ?? 0,
      availableQuantity: json['available_quantity'] ?? 0,
      minimumQuantity: json['minimum_quantity'] ?? 5,
      status: json['status'] ?? 'Available',
    );
  }
}
