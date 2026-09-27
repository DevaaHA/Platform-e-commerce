import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class WishlistProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _wishlistItems = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;

  // جلب قائمة المفضلة من الخادم
  Future<void> fetchWishlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // استخدام ApiConstants.wishlist المعتمد في مشروعك
      final response = await _apiService.dio.get(
        ApiConstants.wishlist,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        _wishlistItems = List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      debugPrint('Error fetching wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // إضافة أو إزالة منتج من المفضلة
  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    final productId = product['id'];
    final bool isCurrentlyFavorite = isProductFavorite(productId);

    // تحديث واجهة المستخدم لحظياً (Optimistic Update)
    if (isCurrentlyFavorite) {
      _wishlistItems.removeWhere((item) => item['id'] == productId);
    } else {
      _wishlistItems.add(product);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (isCurrentlyFavorite) {
        // حذف من المفضلة
        await _apiService.dio.delete(
          '${ApiConstants.wishlist}$productId/',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } else {
        // إضافة للمفضلة
        await _apiService.dio.post(
          ApiConstants.wishlist,
          data: {'product_id': productId},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      // التراجع عن التعديل في حال فشل الطلب بالخادم
      if (isCurrentlyFavorite) {
        _wishlistItems.add(product);
      } else {
        _wishlistItems.removeWhere((item) => item['id'] == productId);
      }
      notifyListeners();
      debugPrint('Error toggling favorite: $e');
    }
  }

  // التحقق مما إذا كان المنتج مفضلاً
  bool isProductFavorite(dynamic productId) {
    return _wishlistItems.any((item) => item['id'] == productId);
  }
}
