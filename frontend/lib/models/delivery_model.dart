class DeliveryModel {
  final String id;
  final String orderId;
  final String storeName;
  final String customerAddress;
  final double distance;
  final double amount;
  final String status;

  DeliveryModel({
    required this.id,
    required this.orderId,
    required this.storeName,
    required this.customerAddress,
    required this.distance,
    required this.amount,
    required this.status,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      storeName: json['store_name'] ?? 'متجر سوق جو',
      customerAddress: json['customer_address'] ?? 'عناوين التوصيل',
      distance: double.tryParse(json['distance']?.toString() ?? '0') ?? 0.0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'Assigned',
    );
  }
}
