class StoreModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String email;
  final String phone;
  final String logo;
  final String status;
  final bool isFeatured;

  StoreModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.email,
    required this.phone,
    required this.logo,
    required this.status,
    required this.isFeatured,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      logo: json['logo'] ?? '',
      status: json['status'] ?? 'Pending',
      isFeatured: json['featured'] ?? false,
    );
  }
}
