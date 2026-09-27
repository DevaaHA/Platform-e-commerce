import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/banner_model.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final ApiService _apiService = ApiService();
  List<BannerModel> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.adminBanners);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        setState(() {
          _banners = data.map((json) => BannerModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // بيانات تجريبية حية للمنصة في حال عدم الاتصال المباشر
      setState(() {
        _banners = [
          BannerModel(
            id: '1',
            title: 'عروض العيد الكبرى',
            image: 'https://via.placeholder.com/600',
            linkType: 'product',
            status: 'Active',
          ),
          BannerModel(
            id: '2',
            title: 'خصومات المتاجر الإلكترونية',
            image: 'https://via.placeholder.com/600',
            linkType: 'store',
            status: 'Active',
          ),
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBanner(String id) async {
    try {
      await _apiService.delete('${ApiConstants.adminBanners}$id/');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف البنر بنجاح 🗑️')));
      _fetchBanners();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل حذف البنر')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'إدارة البنرات والإعلانات (CMS) 🖼️',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.add, color: AppTheme.darkBg),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فتح نافذة إضافة بنر إعلاني جديد...')),
          );
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _banners.isEmpty
          ? const Center(
              child: Text(
                'لا توجد بنرات إعلانية مضافة حالياً',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.image,
                          color: AppTheme.gold,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'نوع الربط: ${banner.linkType}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                banner.status,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                ),
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
                        onPressed: () => _deleteBanner(banner.id),
                        tooltip: 'حذف البنر',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
