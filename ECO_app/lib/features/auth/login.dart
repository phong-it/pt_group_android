import 'package:flutter/material.dart';
import '../../main_wrapper.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true; 
  bool _isLoading = false; 
  
  final _authService = AuthService();
  
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
    // ĐỔI MÀU TỰ ĐỘNG: Đăng nhập thì Xanh lá, Đăng ký thì Xanh dương
    final Color primaryColor = _isLogin ? Colors.green : Colors.blue;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo đổi màu
              Icon(Icons.eco, size: 100, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'EcoTrade',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Chào mừng bạn quay trở lại!' : 'Tham gia cộng đồng tái chế ngay!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // CHỈ HIỆN KHI ĐĂNG KÝ (Tên và Địa chỉ)
              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person, color: primaryColor), // Icon đổi màu
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ',
                    prefixIcon: Icon(Icons.location_on, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone, // Bật bàn phím số
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(Icons.phone, color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Ô nhập Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ô nhập Mật khẩu
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: Icon(Icons.lock, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nút Hành động Chính
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, // Nền nút đổi màu
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    String? errorMessage;

                    if (_isLogin) {
                      errorMessage = await _authService.signIn(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );
                    } else {
                      // Bắt lỗi quên nhập thông tin
                      if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
                        errorMessage = "Vui lòng nhập đầy đủ Họ tên và Địa chỉ!";
                      } else {
                        errorMessage = await _authService.signUp(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                          name: _nameController.text.trim(),
                          address: _addressController.text.trim(), // Truyền địa chỉ xuống
                          phone: _phoneController.text.trim(),
                        );
                      }
                    }

                    setState(() => _isLoading = false);

                    if (errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                      );
                    } else {
                      // KIỂM TRA LUỒNG CHUYỂN TRANG
                      if (_isLogin) {
                        // Nếu ĐĂNG NHẬP thành công -> Vào App chính
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đăng nhập thành công!"), backgroundColor: Colors.green),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MainWrapper()),
                        );
                      } else {
                        // Nếu ĐĂNG KÝ thành công -> Chuyển về UI Đăng nhập, xóa trắng mật khẩu
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đăng ký thành công! Vui lòng đăng nhập."), backgroundColor: Colors.blue),
                        );
                        setState(() {
                          _isLogin = true; // Lật UI về Xanh lá
                          _passwordController.clear(); // Bắt người dùng tự nhập lại pass cho bảo mật
                        });
                      }
                    }
                  },
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Chữ bấm chuyển đổi dưới cùng
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin 
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
}