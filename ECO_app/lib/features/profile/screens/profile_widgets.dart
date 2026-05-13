import 'package:flutter/material.dart';
import 'package:frontend/shared/models/user_model.dart';

// ---------------------------------------------------------
// 1. WIDGET: HEADER PHÍA TRÊN CÙNG (SLIVER APP BAR)
// ---------------------------------------------------------
class ProfileHeader extends StatelessWidget {
  final UserModel? user;
  
  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      backgroundColor: Colors.green[600],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(user?.avatar ?? 'https://ui-avatars.com/api/?name=User'),
                    onBackgroundImageError: (e, s) {},
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Khách hàng',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    (user?.role == 'admin') ? '🌟 Quản trị viên' : '👤 Thành viên',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. WIDGET: THẺ THỐNG KÊ (ĐIỂM ECO, ĐƠN MUA...)
// ---------------------------------------------------------
class ProfileStatCard extends StatelessWidget {
  final UserModel? user;

  const ProfileStatCard({super.key, required this.user});

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatColumn('Điểm Eco', '${user?.ecoPoints ?? 0}', Icons.eco, Colors.green),
            Container(height: 40, width: 1, color: Colors.grey[300]),
            _buildStatColumn('Đơn mua', '0', Icons.shopping_bag, Colors.orange),
            Container(height: 40, width: 1, color: Colors.grey[300]),
            _buildStatColumn('Tin đăng', '0', Icons.storefront, Colors.blue),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3. WIDGET: DÒNG THÔNG TIN (EMAIL, SĐT, ĐỊA CHỈ)
// ---------------------------------------------------------
class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ProfileInfoTile({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.black54),
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
    );
  }
}