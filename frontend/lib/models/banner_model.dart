class BannerModel {
  final String id;
  final String title;
  final String image;
  final String linkType;
  final String status;

  BannerModel({
    required this.id,
    required this.title,
    required this.image,
    required this.linkType,
    required this.status,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'بنر إعلاني',
      image: json['image'] ?? '',
      linkType: json['link_type'] ?? 'product',
      status: json['status'] ?? 'Active',
    );
  }
}
