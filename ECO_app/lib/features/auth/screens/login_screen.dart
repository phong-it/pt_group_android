import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main_wrapper.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe authProvider để tự động cập nhật UI khi trạng thái thay đổi
    final authProvider = context.watch<AuthProvider>();
    
    final bool isLogin = authProvider.isLogin;
    final bool isLoading = authProvider.isLoading;
    final Color primaryColor = isLogin ? Colors.green : Colors.blue;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.eco, size: 100, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'EcoTrade',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin ? 'Chào mừng bạn quay trở lại!' : 'Tham gia cộng đồng tái chế ngay!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              if (!isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Họ và tên', Icons.person, primaryColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: _buildInputDecoration('Địa chỉ', Icons.location_on, primaryColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration('Số điện thoại', Icons.phone, primaryColor),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration('Email', Icons.email, primaryColor),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _buildInputDecoration('Mật khẩu', Icons.lock, primaryColor),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : () => _handleAuthenticate(context),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                // Thay vì setState, ta gọi hàm từ provider bằng context.read()
                onPressed: () => context.read<AuthProvider>().toggleAuthMode(),
                child: Text(
                  isLogin
                      ? 'Chưa có tài khoản? Bấm vào đây để Đăng ký'
                      : 'Đã có tài khoản? Quay lại Đăng nhập',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Đưa hàm xử lý logic ra ngoài để hàm build() gọn hơn
  Future<void> _handleAuthenticate(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    final errorMessage = await authProvider.authenticate(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!context.mounted) return;

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } else {
      if (authProvider.isLogin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng nhập thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công! Vui lòng đăng nhập."), backgroundColor: Colors.blue),
        );
        authProvider.setLoginMode(true);
        _passwordController.clear();
      }
    }
  }

  // Tách hàm tạo style InputDecoration để code bớt lặp lại
  InputDecoration _buildInputDecoration(String label, IconData icon, Color primaryColor) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}