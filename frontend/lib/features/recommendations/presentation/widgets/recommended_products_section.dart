import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/recommendation_model.dart';

class RecommendedProductsSection extends StatefulWidget {
  const RecommendedProductsSection({super.key});

  @override
  State<RecommendedProductsSection> createState() =>
      _RecommendedProductsSectionState();
}

class _RecommendedProductsSectionState
    extends State<RecommendedProductsSection> {
  final ApiService _apiService = ApiService();
  List<RecommendationModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final response = await _apiService.get(ApiConstants.userRecommendations);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        setState(() {
          _products = data
              .map((json) => RecommendationModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // بيانات تجريبية ذكية للمنصة في حال عدم الاتصال المباشر بالسيرفر
      setState(() {
        _products = [
          RecommendationModel(
            id: 'rec-1',
            name: 'ساعة ذكية رياضية فائقة',
            price: 45.0,
            image: 'https://via.placeholder.com/200',
            rating: 4.8,
          ),
          RecommendationModel(
            id: 'rec-2',
            name: 'سماعات بلوتوث لاسلكية',
            price: 25.0,
            image: 'https://via.placeholder.com/200',
            rating: 4.6,
          ),
          RecommendationModel(
            id: 'rec-3',
            name: 'حقيبة ظهر للاب توب مقاومة للماء',
            price: 35.0,
            image: 'https://via.placeholder.com/200',
            rating: 4.9,
          ),
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(String productId) async {
    try {
      await _apiService.post(
        ApiConstants.cart,
        data: {'product_id': productId, 'quantity': 1},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إفاضة المنتج المقترح إلى السلة بنجاح 🛒'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل إضافة المنتج للسلة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      );
    }

    if (_products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'مختارة خصيصاً لك (Recommended For You) ✨',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: AppTheme.gold,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price} د.أ',
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: AppTheme.darkBg,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _addToCart(product.id),
                        child: const Text(
                          'إضافة للسلة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
