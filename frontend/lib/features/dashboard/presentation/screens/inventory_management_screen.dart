import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/inventory_model.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final ApiService _apiService = ApiService();
  List<InventoryModel> _inventoryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.inventoryList);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        setState(() {
          _inventoryItems = data
              .map((json) => InventoryModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل تحميل بيانات المخزون')));
    }
  }

  Future<void> _adjustStock(
    String inventoryId,
    int changeAmount,
    String reason,
  ) async {
    try {
      await _apiService.post(
        ApiConstants.inventoryAdjust,
        data: {
          'inventory_id': inventoryId,
          'amount': changeAmount,
          'reason': reason,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المخزون وسجل الحركة بنجاح 📦')),
      );
      _fetchInventory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تعديل المخزون. تأكد من الكمية.')),
      );
    }
  }

  void _showAdjustDialog(InventoryModel item) {
    final controller = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'تعديل مخزون: ${item.productName}',
          style: const TextStyle(color: AppTheme.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'الكمية المراد تعديلها',
                labelStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'السبب (مثال: توريد جديد، تلف)',
                labelStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.darkBg,
            ),
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                _adjustStock(item.id, amount, reasonController.text);
              }
            },
            child: const Text('تأكيد'),
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
        title: const Text(
          'إدارة المخزون (Inventory Ledger)',
          style: TextStyle(color: AppTheme.gold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.white),
            onPressed: _fetchInventory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _inventoryItems.isEmpty
          ? const Center(
              child: Text(
                'لا توجد بيانات مخزون متاحة',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _inventoryItems.length,
              itemBuilder: (context, index) {
                final item = _inventoryItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.availableQuantity <= item.minimumQuantity
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU: ${item.sku}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'الإجمالي: ${item.quantity}',
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'محجوز: ${item.reservedQuantity}',
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'المتاح: ${item.availableQuantity}',
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: AppTheme.gold,
                          size: 28,
                        ),
                        onPressed: () => _showAdjustDialog(item),
                        tooltip: 'تعديل المخزون',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
