import 'package:flutter/material.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';

// 1. IMPORT CÁC FILE CỦA BẠN (NGƯỜI A)
import 'features/products/screens/product_list_screen.dart';
import 'features/store_map/screens/map_screen.dart';
import 'features/notifications/screens/notification_screen.dart';
import 'features/products/screens/add_edit_product_screen.dart';

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
    const MapScreen(),         // Index 1: Tab của A
    const NotificationScreen(),// Index 2: Tab của A
    CartScreen(),              // Index 3: Tab của B (Class trong file cart_page.dart của Phong)
    ProfileScreen(),
  ];

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
        onTap: (index) {
          // Lệnh setState giúp vẽ lại giao diện khi chuyển tab
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Giữ cho 4 nút đứng im, không bị co giãn
        selectedItemColor: Colors.green,     // Màu xanh khi đang ở tab đó
        unselectedItemColor: Colors.grey,    // Màu xám khi ở tab khác
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: 'Chợ đồ cũ'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map), 
            label: 'Bản đồ'
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
            label: 'Profile'
          ),
        ],
      ),
    );
  }
}