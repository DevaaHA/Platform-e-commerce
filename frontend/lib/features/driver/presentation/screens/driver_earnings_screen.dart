import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _earningsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.driverEarnings);
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _earningsData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'أرباح الكابتن 💰',
          style: TextStyle(color: AppTheme.gold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'أرباح اليوم',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_earningsData['today_earnings'] ?? '0.00'} د.أ',
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          title: const Text(
                            'أرباح الأسبوع',
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: Text(
                            '${_earningsData['week_earnings'] ?? '0.00'} د.أ',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white12),
                        ListTile(
                          title: const Text(
                            'أرباح الشهر',
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: Text(
                            '${_earningsData['month_earnings'] ?? '0.00'} د.أ',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(color: Colors.white12),
                        ListTile(
                          title: const Text(
                            'إجمالي الرحلات المكتملة',
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: Text(
                            '${_earningsData['total_deliveries'] ?? '0'} رحلة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
