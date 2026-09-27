class ReviewModel {
  final String id;
  final String userName;
  final int rating;
  final String comment;
  final bool verifiedPurchase;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.verifiedPurchase,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      userName: json['user_name'] ?? 'مستخدم سري',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      verifiedPurchase: json['verified_purchase'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}
