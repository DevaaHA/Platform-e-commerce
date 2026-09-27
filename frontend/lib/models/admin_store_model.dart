class AdminStoreModel {
  final String id;
  final String name;
  final String ownerName;
  final String city;
  final String status;
  final double sales;
  final double rating;

  AdminStoreModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.city,
    required this.status,
    required this.sales,
    required this.rating,
  });

  factory AdminStoreModel.fromJson(Map<String, dynamic> json) {
    return AdminStoreModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'متجر غير معروف',
      ownerName: json['owner_name'] ?? 'المالك',
      city: json['city'] ?? 'عمان',
      status: json['status'] ?? 'Pending',
      sales: double.tryParse(json['sales']?.toString() ?? '0') ?? 0.0,
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
    );
  }
}
