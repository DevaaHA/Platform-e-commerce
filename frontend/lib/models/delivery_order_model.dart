class DeliveryOrderModel {
  final String id;
  final String storeName;
  final String customerAddress;
  final double deliveryFee;
  final String status;

  DeliveryOrderModel({
    required this.id,
    required this.storeName,
    required this.customerAddress,
    required this.deliveryFee,
    required this.status,
  });

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderModel(
      id: json['id']?.toString() ?? '',
      storeName: json['store_name'] ?? 'متجر سوق جو',
      customerAddress: json['customer_address'] ?? 'عمان، الشارع الرئيسي',
      deliveryFee:
          double.tryParse(json['delivery_fee']?.toString() ?? '2.0') ?? 2.0,
      status: json['status'] ?? 'Ready',
    );
  }
}
