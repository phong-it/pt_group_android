import 'package:flutter/material.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:provider/provider.dart';

import 'features/products/screens/product_list_screen.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'features/products/screens/add_edit_product_screen.dart';
import 'features/notifications/providers/notification_provider.dart'; 
import 'features/auth/providers/auth_provider.dart';

// 2. IMPORT FILE CỦA PHONG (NGƯỜI B)
// Chỉnh lại đường dẫn này nếu thư mục của bạn đặt tên khác
import 'features/cart/screens/cart_screen.dart'; 

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // Biến lưu trữ vị trí tab đang được chọn (mặc định là 0 - Chợ đồ cũ)
  int _currentIndex = 0;

  // Danh sách 4 cánh cửa (4 màn hình chính)
  final List<Widget> _screens = [
    const ProductListScreen(), // Index 0: Tab của A
    const NotificationScreen(),// Index 2: Tab của A
    CartScreen(),              // Index 3: Tab của B (Class trong file cart_page.dart của Phong)
    ProfileScreen(),
  ];

  // 🚀 HÀM KÍCH HOẠT TỰ ĐỘNG TẢI LẠI KHI CHẠM TAB
  void _onTabTapped(int index) {
    // Nếu người dùng bấm trúng Tab Thông báo (Index là 1)
    if (index == 1) {
      final authProvider = context.read<AuthProvider>();
      final notifProvider = context.read<NotificationProvider>();
      final currentUserId = authProvider.userId;

      if (currentUserId != null) {
        // Không sử dụng từ khóa await ở đây để giao diện chuyển Tab lập tức, 
        // luồng mạng chạy ngầm bên dưới mà không gây khựng UI
        notifProvider.fetchNotifications(currentUserId);
      }
    }

    // Luôn luôn cập nhật setState để nhảy sang giao diện Tab mới
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hiển thị nội dung màn hình tương ứng với nút được bấm
      body: _screens[_currentIndex], 
      
      // NÚT BẤM NỔI Ở GIỮA
      floatingActionButton: _currentIndex == 0
        ? FloatingActionButton(
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
          onPressed: () {
            // Bấm vào thì đẩy sang màn hình Đăng bán
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProductScreen()),
            );
          },
        ) : null,

      // Xác định vị trí của nút (bạn đang để ở giữa)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // Thanh điều hướng bên dưới
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed, // Giữ cho 4 nút đứng im, không bị co giãn
        selectedItemColor: Colors.green,     // Màu xanh khi đang ở tab đó
        unselectedItemColor: Colors.grey,    // Màu xám khi ở tab khác
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: 'Chợ đồ cũ'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications), 
            label: 'Thông báo'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), 
            label: 'Giỏ hàng'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Cá nhân'
          ),
        ],
      ),
    );
  }
}