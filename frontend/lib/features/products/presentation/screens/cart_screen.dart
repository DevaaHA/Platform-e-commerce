import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/cart_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  List<CartItemModel> _cartItems = [];
  bool _isLoading = true;
  double _subtotal = 0.0;
  double _tax = 0.0;
  final double _shipping = 2.0; // جعلناه final كما طلبت أداة التحليل
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.cart);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = response.data;
        final List itemsJson = data['items'] ?? (data is List ? data : []);

        setState(() {
          _cartItems = itemsJson
              .map((json) => CartItemModel.fromJson(json))
              .toList();
          _subtotal =
              double.tryParse(data['subtotal']?.toString() ?? '0') ??
              _calculateSubtotal();
          _tax = _subtotal * 0.16; // ضريبة القيمة المضافة 16% في الأردن
          _total = _subtotal + _tax + _shipping;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double _calculateSubtotal() {
    double sum = 0;
    for (var item in _cartItems) {
      sum += item.unitPrice * item.quantity;
    }
    return sum;
  }

  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return;
    try {
      await _apiService.patch(
        ApiConstants.cartItemDetail(itemId),
        data: {'quantity': newQuantity},
      );
      _fetchCart();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحديث الكمية. تأكد من توفر المخزون.'),
        ),
      );
    }
  }

  Future<void> _removeItem(String itemId) async {
    try {
      await _apiService.delete(ApiConstants.cartItemDetail(itemId));
      _fetchCart();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل حذف المنتج من السلة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'سلة المشتريات (Cart)',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'سلة التسوق فارغة حالياً',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.darkBg,
                    ),
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text('تصفح المنتجات الآن'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
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
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(
                                      item.imageUrl,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'المتجر: ${item.storeName}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item.unitPrice} د.أ',
                                    style: const TextStyle(
                                      color: AppTheme.gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => _updateQuantity(
                                    item.id,
                                    item.quantity - 1,
                                  ),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppTheme.gold,
                                    size: 20,
                                  ),
                                  onPressed: () => _updateQuantity(
                                    item.id,
                                    item.quantity + 1,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _removeItem(item.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // ملخص الفاتورة وزر اتمام الطلب (Checkout)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'المجموع الفرعي:',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          Text(
                            '${_subtotal.toStringAsFixed(2)} د.أ',
                            style: const TextStyle(color: AppTheme.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الضريبة (16%):',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          Text(
                            '${_tax.toStringAsFixed(2)} د.أ',
                            style: const TextStyle(color: AppTheme.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'رسوم التوصيل:',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                          Text(
                            '${_shipping.toStringAsFixed(2)} د.أ',
                            style: const TextStyle(color: AppTheme.white),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'المجموع النهائي:',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${_total.toStringAsFixed(2)} د.أ',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: AppTheme.darkBg,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'جاهز للانتقال لمرحلة الدفع وإتمام الطلب (Checkout)! 🚀',
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'متابعة الدفع وإتمام الطلب',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
