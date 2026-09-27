import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _cartData;
  bool _isLoading = true;
  String? _errorMessage;

  // 🎟️ متغيرات الكوبونات
  final TextEditingController _couponController = TextEditingController();
  double _discount = 0.00;
  String _appliedCouponName = '';

  // 💰 متغيرات المحفظة والدفع
  double _walletBalance = 18.90;
  bool _payWithWallet = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadWalletBalance();
    await fetchCartData();
  }

  Future<void> _loadWalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _walletBalance = prefs.getDouble('wallet_balance') ?? 18.90;
    });
  }

  // 🚀 جلب بيانات السلة الحقيقية من Django API
  Future<void> fetchCartData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'الرجاء تسجيل الدخول لعرض سلة التسوق';
            _isLoading = false;
          });
        }
        return;
      }

      final response = await _apiService.dio.get(
        ApiConstants.cart,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        setState(() {
          _cartData = response.data;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل جلب بيانات السلة. تأكد من الاتصال.';
          _isLoading = false;
        });
      }
    }
  }

  // 🔄 تعديل الكمية
  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) {
      _removeItem(itemId);
      return;
    }

    setState(() {
      final rawItems = _cartData?['items'];
      if (rawItems is List) {
        for (var item in rawItems) {
          if (item is Map && item['id'].toString() == itemId) {
            item['quantity'] = newQuantity;
            final price =
                double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
            item['subtotal'] = (price * newQuantity).toStringAsFixed(2);
            break;
          }
        }
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      await _apiService.dio.patch(
        ApiConstants.cartItemDetail(itemId),
        data: {'quantity': newQuantity},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      fetchCartData();
    } catch (e) {
      fetchCartData();
    }
  }

  // ❌ حذف عنصر من السلة
  Future<void> _removeItem(String itemId) async {
    setState(() {
      final rawItems = _cartData?['items'];
      if (rawItems is List) {
        rawItems.removeWhere(
          (item) => item is Map && item['id'].toString() == itemId,
        );
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      await _apiService.dio.delete(
        ApiConstants.cartItemDetail(itemId),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      fetchCartData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف العنصر من السلة'),
          backgroundColor: Colors.redAccent,
          duration: Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      fetchCartData();
    }
  }

  // 🎟️ تطبيق الكوبون الفعلي
  void _applyCoupon(double subtotal) {
    String code = _couponController.text.trim().toUpperCase();
    setState(() {
      if (code == 'SOUQ50' || code == 'SUMMER50') {
        _discount = subtotal * 0.50; // خصم 50%
        _appliedCouponName = 'خصم 50% الصيفي ($code)';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 تم تطبيق الكوبون بنجاح! خصم 50%'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (code == 'WELCOME10') {
        _discount = 5.00; // خصم 5 دنانير
        _appliedCouponName = 'كوبون ترحيبي (5.00 د.أ)';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 تم تطبيق خصم 5 دنانير بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _discount = 0.00;
        _appliedCouponName = '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ كود الكوبون غير صحيح أو منتهي الصلاحية'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  double _calculateSubtotal(List<dynamic> items) {
    double sum = 0.0;
    for (var item in items) {
      if (item is Map) {
        final subtotal =
            double.tryParse(item['subtotal']?.toString() ?? '0') ?? 0.0;
        sum += subtotal;
      }
    }
    return sum;
  }

  int _calculateTotalItems(List<dynamic> items) {
    int count = 0;
    for (var item in items) {
      if (item is Map) {
        final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        count += qty;
      }
    }
    return count;
  }

  // 🛍️ إتمام الشراء والدفع الفعلي من المحفظة أو عند الاستلام
  Future<void> _checkoutOrder(double grandTotal) async {
    final prefs = await SharedPreferences.getInstance();

    if (_payWithWallet) {
      if (_walletBalance < grandTotal) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ رصيد المحفظة غير كافٍ لإتمام الطلب. يرجى الشحن أو اختيار طريقة أخرى.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      _walletBalance -= grandTotal;
      await prefs.setDouble('wallet_balance', _walletBalance);
    }

    String orderId =
        'SOQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '🎉 تم إتمام الطلب بنجاح!',
          style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'رقم الطلب: #$orderId\nالإجمالي المدفوع: ${grandTotal.toStringAsFixed(2)} د.أ\n${_payWithWallet ? "تم الخصم مباشرة من محفظتك المالية 💰" : "الدفع عند الاستلام 💵"}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
            onPressed: () {
              Navigator.pop(context);
              fetchCartData(); // تحديث السلة بعد الطلب
            },
            child: const Text(
              'حسناً',
              style: TextStyle(
                color: AppTheme.darkBg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          '🛒 سلة التسوق الذكية',
          style: TextStyle(
            color: AppTheme.gold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: fetchCartData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _cartData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      );
    }

    if (_errorMessage != null && _cartData == null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.orange, fontSize: 14),
        ),
      );
    }

    final rawItems = _cartData?['items'];
    final List<dynamic> items = (rawItems is List) ? rawItems : [];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            const Text(
              'سلتك فارغة حالياً 🛍️',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
              onPressed: fetchCartData,
              child: const Text(
                'تحديث السلة',
                style: TextStyle(color: AppTheme.darkBg),
              ),
            ),
          ],
        ),
      );
    }

    final double productsSubtotal = _calculateSubtotal(items);
    final int totalItemsCount = _calculateTotalItems(items);
    const double deliveryFee = 2.00;
    final double taxAmount = productsSubtotal * 0.16;
    final double grandTotal =
        ((productsSubtotal + deliveryFee + taxAmount) - _discount) < 0
        ? 0
        : (productsSubtotal + deliveryFee + taxAmount) - _discount;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.surfaceDark.withAlpha(150),
          child: Text(
            'لديك ($totalItemsCount) قطع في سلتك (${items.length} أصناف مختلفة)',
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is! Map) return const SizedBox.shrink();

              String name = 'بلوزة قطن';
              if (item.containsKey('product_name') &&
                  item['product_name'] != null) {
                name = item['product_name'].toString();
              } else {
                final productField = item['product'];
                if (productField is Map) {
                  name = productField['name']?.toString() ?? 'بلوزة قطن';
                }
              }

              final String itemId = item['id']?.toString() ?? '';
              final String price = item['unit_price']?.toString() ?? '0.00';
              final int quantity =
                  int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
              final String subtotal = item['subtotal']?.toString() ?? '0.00';

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
                      child: Container(
                        width: 70,
                        height: 70,
                        color: const Color(0xFF2A2D3E),
                        child: const Icon(
                          Icons.image,
                          color: Colors.white24,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'السعر: $price د.أ',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المجموع: $subtotal د.أ',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2D3E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          _updateQuantity(itemId, quantity - 1),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          _updateQuantity(itemId, quantity + 1),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color: AppTheme.gold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () => _removeItem(itemId),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // 📋 الفاتورة السفلية متضمنة الكوبون والدفع بالمحفظة
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎟️ حقل إدخال الكوبون
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'كود الكوبون (مثل: SOUQ50)',
                        hintStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                    ),
                    onPressed: () => _applyCoupon(productsSubtotal),
                    child: const Text(
                      'تطبيق',
                      style: TextStyle(
                        color: AppTheme.darkBg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (_appliedCouponName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '✅ تم تطبيق: $_appliedCouponName',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // 💰 زر تبديل الدفع من المحفظة
              SwitchListTile(
                secondary: const Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.gold,
                  size: 22,
                ),
                title: const Text(
                  'الدفع من رصيد المحفظة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'الرصيد: ${_walletBalance.toStringAsFixed(2)} د.أ',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                value: _payWithWallet,
                activeTrackColor: AppTheme.gold,
                dense: true,
                onChanged: (val) {
                  setState(() {
                    _payWithWallet = val;
                  });
                },
              ),
              const Divider(color: Colors.white12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'مجموع المنتجات:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    '${productsSubtotal.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الضريبة (16%):',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    '${taxAmount.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'رسوم التوصيل:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    '${deliveryFee.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              if (_discount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'قيمة الخصم:',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 13),
                    ),
                    Text(
                      '- ${_discount.toStringAsFixed(2)} د.أ',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: Colors.white12),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإجمالي النهائي:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${grandTotal.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _checkoutOrder(grandTotal),
                  child: const Text(
                    'إتمام الشراء والدفع الآمن 🛍️',
                    style: TextStyle(
                      color: AppTheme.darkBg,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
