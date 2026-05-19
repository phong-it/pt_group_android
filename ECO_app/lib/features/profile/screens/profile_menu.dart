import 'package:flutter/material.dart';
import 'package:frontend/shared/models/user_model.dart';
import '../../orders/screens/order_history_screen.dart';

class ProfileMenu extends StatelessWidget {
  final UserModel? user; // Đã đổi từ dynamic sang UserModel?
  final VoidCallback onEditProfileTap;
  final VoidCallback onLogoutTap;

  const ProfileMenu({
    super.key,
    required this.user,
    required this.onEditProfileTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Thông tin cá nhân'),
          _buildMenuBlock([
            _buildMenuItem(
              icon: Icons.email_outlined,
              title: 'Email',
              subtitle: user?.email ?? 'Chưa cập nhật',
              iconColor: const Color(0xFF6366F1),
              showArrow: false,
            ),
            _buildMenuItem(
              icon: Icons.phone_outlined,
              title: 'Số điện thoại',
              subtitle: user?.phone ?? 'Chưa cập nhật',
              iconColor: const Color(0xFF14B8A6),
              showArrow: false,
            ),
            _buildMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Địa chỉ',
              subtitle: user?.address ?? 'Chưa cập nhật',
              iconColor: const Color(0xFFF59E0B),
              showArrow: false,
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('Hoạt động của tôi'),
          _buildMenuBlock([
            _buildMenuItem(
              icon: Icons.history_rounded,
              title: 'Lịch sử đơn hàng',
              subtitle: 'Theo dõi đơn hàng & hóa đơn',
              iconColor: Colors.blueAccent,
              onTap: () {
                // Logic điều hướng sang Order History
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
                print('Chuyển hướng sang Lịch sử đơn hàng');
              },
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('Thiết lập tài khoản'),
          _buildMenuBlock([
            _buildMenuItem(
              icon: Icons.manage_accounts_outlined,
              title: 'Cập nhật hồ sơ',
              iconColor: const Color(0xFF3B82F6),
              onTap: onEditProfileTap,
            ),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Chính sách bảo mật',
              iconColor: const Color(0xFF64748B),
              onTap: () {
                // Logic webview hoặc điều hướng chính sách
              },
            ),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Đăng xuất',
              iconColor: const Color(0xFFEF4444),
              onTap: onLogoutTap,
              isLogout: true,
              showArrow: false,
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Tiêu đề phân đoạn để UI rõ ràng hơn
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // Gom nhóm các menu vào một khối trắng bo góc (Modern Card UI)
  Widget _buildMenuBlock(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget widget = entry.value;
          // Thêm đường kẻ giữa các item, trừ item cuối cùng
          return Column(
            children: [
              widget,
              if (idx != children.length - 1)
                const Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: Color(0xFFF1F5F9),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    VoidCallback? onTap,
    bool showArrow = true,
    bool isLogout = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isLogout ? FontWeight.w600 : FontWeight.w500,
          color: isLogout ? Colors.red : const Color(0xFF1E293B),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: showArrow
          ? const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            )
          : null,
    );
  }
}
