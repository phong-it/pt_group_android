import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final dynamic user;
  final VoidCallback onEditAvatarTap;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEditAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = user?.avatar != null && user!.avatar!.isNotEmpty;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background xanh lá cách điệu (Gradient + Họa tiết chìm)
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(35),
            bottomRight: Radius.circular(35),
          ),
          child: Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B5E20), // Xanh lá rất đậm
                  Color(0xFF2E7D32), // Xanh lá đậm
                  Color(0xFF4CAF50), // Xanh lá chuẩn
                ],
              ),
            ),
            child: Stack(
              children: [
                // Họa tiết vòng tròn mờ trang trí góc trên phải
                Positioned(
                  top: -40,
                  right: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Họa tiết vòng tròn mờ trang trí góc dưới trái
                Positioned(
                  bottom: -50,
                  left: -20,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Thanh Header (Logo & Nút Menu)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 10),
                            const Text('Hồ sơ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Icon(Icons.more_vert, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Thông tin User (Avatar + Tên)
        Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Khối Avatar
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3), // Viền trắng mờ
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      backgroundImage: hasAvatar
                          ? NetworkImage(user!.avatar!)
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    ),
                  ),
                  // Nút edit avatar
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onEditAvatarTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                          ],
                        ),
                        child: Icon(Icons.camera_alt, size: 16, color: Colors.green[700]), // Đổi icon thành camera cho hợp lý
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 16),
              // Khối Tên & ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Khách hàng',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ID: ${user?.phone ?? 'Chưa cập nhật'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Khối 2 Thẻ nổi (Điểm Eco & Vai trò)
        Container(
          margin: const EdgeInsets.only(top: 220, left: 20, right: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.eco_rounded,
                  iconColor: Colors.green[600]!,
                  iconBg: Colors.green.withOpacity(0.12),
                  title: 'Điểm Eco',
                  value: '${user?.ecoPoints ?? 0}',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.admin_panel_settings_outlined,
                  iconColor: Colors.amber[700]!, // Đổi màu icon cho nổi bật
                  iconBg: Colors.amber.withOpacity(0.12),
                  title: 'Vai trò',
                  value: (user?.role == 'admin') ? 'Quản trị' : 'Thành viên',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget hỗ trợ build thẻ nổi
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}