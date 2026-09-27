import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  // قائمة رغبات حقيقية ومتحركة (Stateful)
  final List<Map<String, dynamic>> _wishlistItems = [
    {'id': '1', 'name': 'جاكيت شتوي جلد فاخر', 'price': '45.00 د.أ'},
    {'id': '2', 'name': 'حذاء رياضي نايك أير ماكس', 'price': '65.00 د.أ'},
  ];

  // دالة إزالة منتج من المفضلة
  void _removeItem(String id, String name) {
    setState(() {
      _wishlistItems.removeWhere((item) => item['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ تمت إزالة "$name" من المفضلة'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // دالة نقل المنتج إلى السلة
  void _moveToCart(Map<String, dynamic> item) {
    setState(() {
      _wishlistItems.removeWhere((i) => i['id'] == item['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛒 تم نقل "${item['name']}" إلى سلة التسوق بنجاح!'),
        backgroundColor: Colors.green,
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
          '❤️ المنتجات المفضلة لديك',
          style: TextStyle(color: AppTheme.gold, fontSize: 16),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: _wishlistItems.isEmpty
          ? const Center(
              child: Text(
                'قائمة المفضلة فارغة حالياً 🤍',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _wishlistItems.length,
              itemBuilder: (context, index) {
                final item = _wishlistItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: AppTheme.gold,
                      ),
                    ),
                    title: Text(
                      item['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item['price'],
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // زر النقل إلى السلة
                        IconButton(
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            color: AppTheme.gold,
                            size: 22,
                          ),
                          tooltip: 'نقل إلى السلة',
                          onPressed: () => _moveToCart(item),
                        ),
                        // زر الحذف من المفضلة
                        IconButton(
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                          tooltip: 'إزالة من المفضلة',
                          onPressed: () =>
                              _removeItem(item['id'], item['name']),
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
