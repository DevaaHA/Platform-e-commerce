import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 🚀 المتغير المسؤول عن حفظ القسم المحدد حالياً
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // 🚀 1. جلب المنتجات الحقيقية من Django (مع دعم البحث والفلترة بالأقسام)
  Future<void> _fetchProducts({String? searchQuery, String? categoryId}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String endpoint = ApiConstants.products;

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        endpoint = '${ApiConstants.searchProducts}?q=$searchQuery';
      } else if (categoryId != null) {
        endpoint = '${ApiConstants.products}?category=$categoryId';
      }

      final response = await _apiService.get(endpoint);

      if (mounted) {
        setState(() {
          if (response.data is Map && response.data.containsKey('results')) {
            _products = response.data['results'];
          } else if (response.data is List) {
            _products = response.data;
          } else {
            _products = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'حدث خطأ أثناء جلب المنتجات. يرجى التأكد من اتصال الخادم.';
          _isLoading = false;
        });
      }
    }
  }

  // 🛒 2. إضافة المنتج للسلة مع إرسال التوكن صراحةً لضمان المصادقة
  Future<void> _addToCart(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _showSnackBar('يجب تسجيل الدخول لإضافة منتجات للسلة', Colors.orange);
        return;
      }

      final response = await _apiService.dio.post(
        ApiConstants.cartItems,
        data: {'product_id': productId, 'quantity': 1},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('تمت الإضافة إلى السلة بنجاح 🛒', Colors.green);
      }
    } catch (e) {
      _showSnackBar(
        'فشل إضافة المنتج للسلة. تحقق من الاتصال.',
        Colors.redAccent,
      );
    }
  }

  // ❤️ 3. إضافة المنتج للمفضلة مع إرسال التوكن صراحةً
  Future<void> _toggleFavorite(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _showSnackBar('يجب تسجيل الدخول أولاً', Colors.orange);
        return;
      }

      await _apiService.dio.post(
        ApiConstants.wishlistItems,
        data: {'product_id': productId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _showSnackBar('تم تحديث قائمة الرغبات ❤️', Colors.green);
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء تحديث المفضلة', Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.gold,
          backgroundColor: AppTheme.surfaceDark,
          onRefresh: _fetchProducts,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                _buildPromoBanner(),
                _buildSectionTitle('الأقسام الرئيسية'),
                _buildCategories(),
                _buildSectionTitle('وصل حديثاً 🔥'),
                _buildMainContent(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white54, size: 50),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
                onPressed: _fetchProducts,
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(color: AppTheme.darkBg),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: Text(
            'لا توجد منتجات متاحة حالياً',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return _buildProductGrid();
  }

  Widget _buildProductGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          final String productId = product['id']?.toString() ?? '';
          final String name = product['name'] ?? 'منتج بدون اسم';
          final String price = product['price']?.toString() ?? '0.00';
          final String imageUrl = product['image'] ?? '';

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2A2D3E),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white24,
                                        size: 40,
                                      ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 50,
                                  color: Colors.white24,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _toggleFavorite(productId),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.darkBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_border,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$price د.أ',
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _addToCart(productId),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.gold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart,
                                color: AppTheme.darkBg,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.white54),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن منتجات، ماركات...',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    _fetchProducts(searchQuery: query.trim());
                  } else {
                    _fetchProducts();
                  }
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: AppTheme.gold, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2D3E), Color(0xFF1F1F2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.gold.withAlpha(50)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'خصم 50%',
                        style: TextStyle(
                          color: AppTheme.darkBg,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'عروض الصيف الكبرى',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.local_mall, size: 80, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'عرض الكل',
            style: TextStyle(color: AppTheme.gold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'icon': Icons.checkroom, 'name': 'ملابس', 'id': '1'},
      {'icon': Icons.watch, 'name': 'إكسسوارات', 'id': '2'},
      {'icon': Icons.phone_iphone, 'name': 'إلكترونيات', 'id': '3'},
      {'icon': Icons.sports_esports, 'name': 'ألعاب', 'id': '4'},
      {'icon': Icons.home, 'name': 'منزل', 'id': '5'},
    ];

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final catId = categories[index]['id'] as String;
          final isSelected = _selectedCategoryId == catId;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedCategoryId = null;
                  _fetchProducts();
                } else {
                  _selectedCategoryId = catId;
                  _fetchProducts(categoryId: catId);
                }
              });
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: index == categories.length - 1 ? 16.0 : 12.0,
                right: index == 0 ? 16.0 : 0,
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.gold.withAlpha(40)
                          : AppTheme.surfaceDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.gold : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      categories[index]['icon'] as IconData,
                      color: isSelected
                          ? AppTheme.gold
                          : AppTheme.gold.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categories[index]['name'] as String,
                    style: TextStyle(
                      color: isSelected ? AppTheme.gold : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
