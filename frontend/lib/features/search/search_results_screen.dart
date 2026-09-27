import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/product_search_model.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final ApiService _apiService = ApiService();
  List<ProductSearchModel> _products = [];
  bool _isLoading = true;
  String _sortBy = 'relevant';

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(
        '${ApiConstants.searchProducts}?q=${widget.query}&sort=$_sortBy',
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        setState(() {
          _products = data
              .map((json) => ProductSearchModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // بيانات تجريبية حية للمنصة في حال عدم الاتصال المباشر بالسيرفر
      setState(() {
        _products = [
          ProductSearchModel(
            id: '1',
            name: 'iPhone 15 Pro Max',
            price: 950.0,
            discountPrice: 890.0,
            image: 'https://via.placeholder.com/300',
            rating: 4.9,
            storeName: 'آبل ستور الأردن',
          ),
          ProductSearchModel(
            id: '2',
            name: 'Samsung Galaxy S24 Ultra',
            price: 900.0,
            image: 'https://via.placeholder.com/300',
            rating: 4.8,
            storeName: 'سامسونج عمان',
          ),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'نتائج البحث عن: "${widget.query}"',
          style: const TextStyle(color: AppTheme.gold, fontSize: 16),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppTheme.gold),
            onSelected: (val) {
              setState(() => _sortBy = val);
              _performSearch();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'relevant', child: Text('الأكثر صلة')),
              const PopupMenuItem(
                value: 'price_low',
                child: Text('السعر: من الأقل للأعلى'),
              ),
              const PopupMenuItem(
                value: 'price_high',
                child: Text('السعر: من الأعلى للأقل'),
              ),
              const PopupMenuItem(
                value: 'rating',
                child: Text('التقييم الأعلى'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _products.isEmpty
          ? const Center(
              child: Text(
                'لم يتم العثور على منتجات تطابق بحثك',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Container(
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
                              size: 40,
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
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.storeName,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${product.price} د.أ',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${product.rating}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
