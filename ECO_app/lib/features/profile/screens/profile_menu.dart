import 'package:flutter/material.dart';

class ProfileMenu extends StatelessWidget {
  final dynamic user;
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          // Hiển thị các thông tin liên hệ dưới dạng Menu
          _buildMenuItem(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: user?.email ?? 'Chưa cập nhật',
            iconColor: const Color(0xFF6366F1), // Tông màu xanh tím nhẹ
            showArrow: false,
          ),
          _buildMenuItem(
            icon: Icons.phone_outlined,
            title: 'Số điện thoại',
            subtitle: user?.phone ?? 'Chưa cập nhật',
            iconColor: const Color(0xFF14B8A6), // Tông màu Teal
            showArrow: false,
          ),
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            title: 'Địa chỉ',
            subtitle: user?.address ?? 'Chưa cập nhật',
            iconColor: const Color(0xFFF59E0B), // Tông màu Amber
            showArrow: false,
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
          ),

          // Các chức năng thao tác
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
              // Thêm logic chuyển hướng nếu có
            },
          ),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            iconColor: const Color(0xFFEF4444), // Đỏ
            onTap: onLogoutTap,
            isLogout: true,
          ),
          
          const SizedBox(height: 40),
        ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      onTap: onTap,
      leading: Icon(
        icon,
        color: iconColor,
        size: 26,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
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
          ? const Icon(Icons.chevron_right_rounded, color: Colors.black54, size: 24)
          : null,
    );
  }
}