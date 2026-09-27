import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../models/user_model.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final ApiService _apiService = ApiService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilterRole = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(ApiConstants.users);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List data = response.data is List
            ? response.data
            : response.data['results'] ?? [];
        setState(() {
          _users = data.map((json) => UserModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _deleteUser(String id) async {
    try {
      await _apiService.dio.delete('${ApiConstants.users}$id/');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المستخدم بنجاح (Soft Delete)')),
      );
      _fetchUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل حذف المستخدم')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      final matchesSearch =
          user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole =
          _selectedFilterRole == 'All' || user.role == _selectedFilterRole;
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          'إدارة المستخدمين - لوحة التحكم',
          style: TextStyle(color: AppTheme.gold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.white),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // شريط البحث والفلترة
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو البريد الإلكتروني...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.gold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedFilterRole,
                  dropdownColor: AppTheme.surfaceDark,
                  style: const TextStyle(color: AppTheme.white),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('جميع الأدوار')),
                    DropdownMenuItem(value: 'Customer', child: Text('عميل')),
                    DropdownMenuItem(
                      value: 'Store Owner',
                      child: Text('صاحب متجر'),
                    ),
                    DropdownMenuItem(value: 'Driver', child: Text('سائق')),
                    DropdownMenuItem(
                      value: 'Super Admin',
                      child: Text('مشرف عام'),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedFilterRole = val!),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // جدول المستخدمين
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.gold),
                    )
                  : filteredUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'لا يوجد مستخدمون مطابقون للبحث',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppTheme.gold,
                                child: Icon(
                                  Icons.person,
                                  color: AppTheme.darkBg,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
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
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.role,
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteUser(user.id),
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
