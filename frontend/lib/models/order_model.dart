class OrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double total;
  final String createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.total,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] ?? 'ORD-000',
      status: json['status'] ?? 'Pending',
      paymentStatus: json['payment_status'] ?? 'Unpaid',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] ?? '',
    );
  }
}
