import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'profile_widgets.dart'; // BẮT BUỘC IMPORT FILE VỪA TẠO Ở BƯỚC 1

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUserData();
    });
  }

  // LOGIC ĐĂNG XUẤT (Giữ nguyên)
  Future<void> _handleLogout(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Provider.of<UserProvider>(context, listen: false).clearUserData();
        // Đẩy về trang Đăng nhập và hủy toàn bộ lịch sử màn hình
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (Route<dynamic> route) => false, // false nghĩa là "Giết hết các trang đang mở"
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;

          if (userProvider.isLoading && user == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          // GIAO DIỆN CHÍNH (Đã được lắp ghép từ các khối Widget)
          return CustomScrollView(
            slivers: [
              // 1. Gọi khối Header
              ProfileHeader(user: user), 

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 2. Gọi khối Thẻ thống kê
                      ProfileStatCard(user: user), 
                      const SizedBox(height: 24),

                      const Align(alignment: Alignment.centerLeft, child: Text('Thông tin cá nhân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 12),
                      
                      // 3. Lắp ghép các khối Dòng thông tin
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            ProfileInfoTile(icon: Icons.email_outlined, title: 'Email', subtitle: user?.email ?? 'Chưa cập nhật'),
                            const Divider(height: 1, indent: 56),
                            ProfileInfoTile(icon: Icons.phone_outlined, title: 'Số điện thoại', subtitle: user?.phone ?? 'Chưa cập nhật'),
                            const Divider(height: 1, indent: 56),
                            ProfileInfoTile(icon: Icons.location_on_outlined, title: 'Địa chỉ', subtitle: user?.address ?? 'Chưa cập nhật'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // NÚT ĐĂNG XUẤT
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.red, width: 1)),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text('Đăng xuất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          onPressed: () => _handleLogout(context),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}