class PaymentModel {
  final String id;
  final String orderId;
  final String paymentMethod;
  final double amount;
  final String status;
  final String createdAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      paymentMethod: json['payment_method'] ?? 'COD',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'Pending',
      createdAt: json['created_at'] ?? '',
    );
  }
}
