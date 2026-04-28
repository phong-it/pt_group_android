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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
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
          (Route<dynamic> route) =>
              false, // false nghĩa là "đóng hết các trang đang mở"
        );
      }
    }
  }

  // LOGIC HIỂN THỊ MODAL CHỈNH SỬA
  void _handleEdit(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    // Khởi tạo các bộ điều khiển nhập liệu với dữ liệu hiện tại
    TextEditingController nameController = TextEditingController(
      text: user?.name,
    );
    TextEditingController phoneController = TextEditingController(
      text: user?.phone,
    );
    TextEditingController addressController = TextEditingController(
      text: user?.address,
    );
    String selectedRole = user?.role ?? 'buyer';
    final List<String> roleOptions = ['buyer', 'seller', 'admin'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        // BỌC STATEFULBUILDER Ở ĐÂY
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chỉnh sửa thông tin',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Ô nhập Họ tên
                  _buildTextField(
                    nameController,
                    'Họ và tên',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  // Ô nhập Số điện thoại
                  _buildTextField(
                    phoneController,
                    'Số điện thoại',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Ô nhập Địa chỉ
                  _buildTextField(
                    addressController,
                    'Địa chỉ',
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 24),
                  // Ô đổi vai trò
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Vai trò',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.green[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.green[600]!,
                          width: 2,
                        ),
                      ),
                    ),
                    items: roleOptions.map((String roleValue) {
                      // Chuyển đổi mã role sang Tiếng Việt để hiển thị cho đẹp
                      String roleDisplay = 'Người mua';
                      if (roleValue == 'seller') roleDisplay = 'Người bán';
                      if (roleValue == 'admin') roleDisplay = 'Quản trị viên';

                      return DropdownMenuItem<String>(
                        value: roleValue,
                        child: Text(roleDisplay),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          // Cập nhật lại UI của Modal khi chọn
                          selectedRole = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Nút Huỷ và Lưu
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            try {
                              // Gọi hàm edit_profile từ Provider
                              await userProvider.edit_profile(
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                address: addressController.text.trim(),
                                role: selectedRole,
                              );
                              if (context.mounted) {
                                Navigator.pop(context); // Đóng modal
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cập nhật thành công!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Lưu thay đổi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget hỗ trợ tạo nhanh các ô nhập liệu
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[600]!, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;

          if (userProvider.isLoading && user == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
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

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Thông tin cá nhân',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. Lắp ghép các khối Dòng thông tin
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            ProfileInfoTile(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              subtitle: user?.email ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 1, indent: 56),
                            ProfileInfoTile(
                              icon: Icons.phone_outlined,
                              title: 'Số điện thoại',
                              subtitle: user?.phone ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 1, indent: 56),
                            ProfileInfoTile(
                              icon: Icons.location_on_outlined,
                              title: 'Địa chỉ',
                              subtitle: user?.address ?? 'Chưa cập nhật',
                            ),
                            const Divider(height: 1, indent: 56),
                            ProfileInfoTile(
                              icon: Icons.person_outlined,
                              title: 'Vai trò',
                              subtitle: user?.role ?? 'Chưa cập nhật',
                            ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            'Đăng xuất',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _handleLogout(context),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // nút chỉnh sữa
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color.fromARGB(
                              255,
                              25,
                              214,
                              72,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text(
                            'Chỉnh sữa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _handleEdit(context),
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
