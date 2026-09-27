import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/product_model.dart';

class StoreProductsScreen extends StatefulWidget {
  const StoreProductsScreen({super.key});

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  final ApiService _apiService = ApiService();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      // الـ Interceptor سيلحق الـ X-Store-ID تلقائياً لتجلب منتجات هذا المتجر فقط
      final response = await _apiService.get(ApiConstants.storeProducts);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        setState(() {
          _products = data.map((json) => ProductModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل تحميل المنتجات')));
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await _apiService.delete(ApiConstants.storeProductDetail(id));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف المنتج بنجاح')));
      _fetchProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل حذف المنتج')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'إدارة منتجات المتجر 📦',
          style: TextStyle(color: AppTheme.gold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.gold, size: 28),
            onPressed: () {
              // الانتقال لصفحة إضافة منتج جديد
              // Navigator.pushNamed(context, '/dashboard/products/create');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _products.isEmpty
          ? const Center(
              child: Text(
                'لا توجد منتجات مضافة في متجرك حالياً',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.white12,
                                child: const Icon(
                                  Icons.image,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nameAr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'السعر: ${product.price} د.أ | المخزون: ${product.stockQuantity}',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deleteProduct(product.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
