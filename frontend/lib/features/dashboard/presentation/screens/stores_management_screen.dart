import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/store_model.dart';

class StoresManagementScreen extends StatefulWidget {
  const StoresManagementScreen({super.key});

  @override
  State<StoresManagementScreen> createState() => _StoresManagementScreenState();
}

class _StoresManagementScreenState extends State<StoresManagementScreen> {
  final ApiService _apiService = ApiService();
  List<StoreModel> _stores = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.stores);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);

        setState(() {
          _stores = data.map((json) => StoreModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تحميل المتاجر. تحقق من الاتصال.')),
      );
    }
  }

  Future<void> _approveStore(String id) async {
    try {
      await _apiService.dio.patch(
        '${ApiConstants.stores}$id/approve/',
        data: {},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اعتماد المتجر بنجاح وتفعيل نشاطه 🚀')),
      );
      _fetchStores();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل اعتماد المتجر')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStores = _stores.where((store) {
      return store.nameAr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          store.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'إدارة المتاجر (Multi-Tenant)',
          style: TextStyle(color: AppTheme.gold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.white),
            onPressed: _fetchStores,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // شريط البحث الذكي
            TextField(
              style: const TextStyle(color: AppTheme.white),
              decoration: InputDecoration(
                hintText: 'بحث باسم المتجر أو البريد الإلكتروني...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 20),
            // قائمة المتاجر
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.gold),
                    )
                  : filteredStores.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد متاجر مطابقة للبحث',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredStores.length,
                      itemBuilder: (context, index) {
                        final store = filteredStores[index];
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
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.gold.withValues(
                                  alpha: 0.2,
                                ),
                                backgroundImage: store.logo.isNotEmpty
                                    ? NetworkImage(store.logo)
                                    : null,
                                child: store.logo.isEmpty
                                    ? const Icon(
                                        Icons.store,
                                        color: AppTheme.gold,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.nameAr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      store.email,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: store.status == 'Active'
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  store.status,
                                  style: TextStyle(
                                    color: store.status == 'Active'
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (store.status == 'Pending')
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.gold,
                                    size: 28,
                                  ),
                                  onPressed: () => _approveStore(store.id),
                                  tooltip: 'اعتماد المتجر',
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
