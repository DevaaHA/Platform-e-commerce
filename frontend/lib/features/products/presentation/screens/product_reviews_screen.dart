import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/review_model.dart';

class ProductReviewsScreen extends StatefulWidget {
  final String productId;

  const ProductReviewsScreen({super.key, required this.productId});

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final ApiService _apiService = ApiService();
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        ApiConstants.productReviews(widget.productId),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = response.data;
        final List itemsJson = data['reviews'] ?? (data is List ? data : []);

        setState(() {
          _reviews = itemsJson
              .map((json) => ReviewModel.fromJson(json))
              .toList();
          _averageRating =
              double.tryParse(data['average_rating']?.toString() ?? '4.8') ??
              4.8;
          _totalReviews = data['total_reviews'] ?? _reviews.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'تقييمات ومراجعات المنتج ⭐',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Column(
              children: [
                // ملخص التقييم العام
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            _averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(Icons.star, color: AppTheme.gold, size: 16),
                              Icon(Icons.star, color: AppTheme.gold, size: 16),
                              Icon(Icons.star, color: AppTheme.gold, size: 16),
                              Icon(Icons.star, color: AppTheme.gold, size: 16),
                              Icon(
                                Icons.star_half,
                                color: AppTheme.gold,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'بناءً على $_totalReviews تقييم',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // قائمة المراجعات
                Expanded(
                  child: _reviews.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد مراجعات لهذا المنتج حتى الآن',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        review.userName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          review.rating,
                                          (index) => const Icon(
                                            Icons.star,
                                            color: AppTheme.gold,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    review.comment,
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (review.verifiedPurchase)
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.greenAccent,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'مشترٍ موثق (Verified Purchase)',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
