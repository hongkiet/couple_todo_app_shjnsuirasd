import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../couple/couple_repository.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onUnpairSuccess;

  const ProfilePage({super.key, this.onUnpairSuccess});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _coupleRepo = CoupleRepository();
  String? _coupleCode;
  bool _isLoading = true;
  bool _isOwner = false;
  String _selectedLanguage = 'VN';
  ThemeMode _themeMode = ThemeMode.system;
  RealtimeChannel? _membershipChannel;
  StreamSubscription<List<dynamic>>? _membershipSub;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
    _subscribeMembershipChanges();
  }

  void _subscribeMembershipChanges() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // 1) Stream-based listener (khuyến nghị): không phụ thuộc Publication
    _membershipSub = Supabase.instance.client
        .from('couple_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((_) async {
          if (mounted) {
            await _loadUserData();
          }
        });

    // 2) Realtime fallback (nếu đã bật Publication)
    _membershipChannel = Supabase.instance.client
        .channel('profile_membership_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'couple_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) async {
            if (mounted) {
              await _loadUserData();
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadUserData() async {
    try {
      final coupleId = await _coupleRepo.myCoupleId();
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      if (coupleId != null && currentUserId != null) {
        // Lấy code từ bảng couples
        final coupleResponse = await Supabase.instance.client
            .from('couples')
            .select('code')
            .eq('id', coupleId)
            .single();

        // Kiểm tra role owner từ bảng couple_members
        final memberResponse = await Supabase.instance.client
            .from('couple_members')
            .select('role')
            .eq('couple_id', coupleId)
            .eq('user_id', currentUserId)
            .maybeSingle();

        setState(() {
          _coupleCode = coupleResponse['code'] as String?;
          _isOwner = memberResponse?['role'] == 'owner';
        });
      } else {
        setState(() {
          _coupleCode = null;
          _isOwner = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading couple data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'VN';
      final themeIndex = prefs.getInt('theme_mode') ?? 0;
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    setState(() {
      _selectedLanguage = language;
    });
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    setState(() {
      _themeMode = mode;
    });

    // Restart app để áp dụng theme mới
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khởi động lại ứng dụng để áp dụng theme mới'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _unpairCouple() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời khỏi cặp đôi'),
        content: const Text(
          '⚠️ Cảnh báo: Khi bạn rời khỏi cặp đôi, '
          'tất cả dữ liệu tasks sẽ bị xóa vĩnh viễn và '
          'người còn lại sẽ không thể sử dụng app nữa.\n\n'
          'Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _coupleRepo.unpairCouple();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã rời khỏi cặp đôi')));
          // Refresh dữ liệu couple trong ProfilePage (sẽ còn được realtime đẩy nữa)
          await _loadUserData();
          // Gọi callback để MainNavigation refresh
          widget.onUnpairSuccess?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e')));
        }
      }
    }
  }

  Future<void> _hardDeleteCouple() async {
    // Cảnh báo mạnh + yêu cầu xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Xóa vĩnh viễn cặp đôi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⚠️ Thao tác KHÔNG THỂ HOÀN TÁC.\n'
                'Toàn bộ tasks, lịch sử, thành viên sẽ bị xóa.\n\n'
                'Nhập DELETE để xác nhận.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nhập DELETE',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(controller.text.trim().toUpperCase() == 'DELETE');
              },
              child: const Text('Xóa vĩnh viễn'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _coupleRepo.hardDeleteCoupleForOwner();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa vĩnh viễn cặp đôi')));

      // Làm mới dữ liệu tại trang Profile
      await _loadUserData();

      // Thông báo cho MainNavigation làm mới (nếu cần)
      widget.onUnpairSuccess?.call();

      // Option: điều hướng về trạng thái không có cặp đôi
      // context.go('/'); // nếu bạn muốn
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi xóa vĩnh viễn: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Thông tin cá nhân
            _buildSection(
              title: '👤 Thông tin cá nhân',
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email ?? 'Không có email',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ngày tạo: ${_formatDate(user?.createdAt)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

            const SizedBox(height: 24),

            // 🎨 Chủ đề
            _buildSection(
              title: '🎨 Chủ đề',
              children: [
                DropdownButtonFormField<ThemeMode>(
                  value: _themeMode,
                  decoration: const InputDecoration(
                    labelText: 'Chế độ hiển thị',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Hệ thống'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Sáng'),
                    ),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _saveThemeMode(value);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🌐 Ngôn ngữ
            _buildSection(
              title: '🌐 Ngôn ngữ',
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Ngôn ngữ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'VN', child: Text('Tiếng Việt')),
                    DropdownMenuItem(value: 'EN', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _saveLanguage(value);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 💞 Thông tin Couple
            _buildSection(
              title: '💞 Thông tin Couple',
              children: [
                if (_coupleCode != null) ...[
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text('Mã cặp đôi'),
                    subtitle: Text(
                      _coupleCode!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _unpairCouple,
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('Rời khỏi cặp đôi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  if (_isOwner) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _hardDeleteCouple,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Xóa vĩnh viễn cặp đôi (owner)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const ListTile(
                    leading: Icon(Icons.favorite_border),
                    title: Text('Chưa kết nối'),
                    subtitle: Text('Bạn chưa tham gia cặp đôi nào'),
                    trailing: Icon(Icons.cancel, color: Colors.grey),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),

            // 🚪 Đăng xuất
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _membershipChannel?.unsubscribe();
    _membershipSub?.cancel();
    super.dispose();
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Không xác định';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Không xác định';
    }
  }
}
