class CouponModel {
  final String id;
  final String code;
  final String name;
  final String type; // percentage, fixed
  final double value;
  final double minimumOrder;
  final String endDate;

  CouponModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.value,
    required this.minimumOrder,
    required this.endDate,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'percentage',
      value: double.tryParse(json['value']?.toString() ?? '0') ?? 0.0,
      minimumOrder:
          double.tryParse(json['minimum_order']?.toString() ?? '0') ?? 0.0,
      endDate: json['end_date'] ?? '',
    );
  }
}
