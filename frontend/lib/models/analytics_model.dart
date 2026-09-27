class AnalyticsModel {
  final double totalSales;
  final int totalOrders;
  final int totalUsers;
  final int totalStores;

  AnalyticsModel({
    required this.totalSales,
    required this.totalOrders,
    required this.totalUsers,
    required this.totalStores,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      totalSales:
          double.tryParse(json['total_sales']?.toString() ?? '150000.0') ??
          150000.0,
      totalOrders:
          int.tryParse(json['total_orders']?.toString() ?? '25000') ?? 25000,
      totalUsers:
          int.tryParse(json['total_users']?.toString() ?? '120000') ?? 120000,
      totalStores:
          int.tryParse(json['total_stores']?.toString() ?? '850') ?? 850,
    );
  }

  static AnalyticsModel jsonToModel(Map<String, dynamic> json) =>
      AnalyticsModel.fromJson(json);
}
