import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../main_wrapper.dart';
import '../providers/auth_provider.dart';
import '../../chat/services/socket_service.dart';
import '../../notifications/providers/notification_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // LOGIC 1: Xử lý xác thực sinh trắc học
  Future<void> _handleBiometricAuth(BuildContext context) async {
    try {
      // Check xem thiết bị có hỗ trợ phần cứng hoặc đã cài vân tay/faceid chưa
      final bool isBiometricSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      if (!isBiometricSupported || !canCheckBiometrics) {
        _showSnackBar(
          context,
          "Thiết bị của bạn không hỗ trợ hoặc chưa thiết lập sinh trắc học.",
          Colors.orange,
        );
        return;
      }

      // Kích hoạt màn hình quét vân tay/FaceID của hệ điều hành
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Quét vân tay hoặc FaceID để đăng nhập vào EcoTrade',
        options: const AuthenticationOptions(
          biometricOnly:
              true, // Bắt buộc dùng sinh trắc học, không cho dùng mã PIN của máy
          stickyAuth: true,
        ),
      );

      if (!context.mounted) return;

      if (didAuthenticate) {
        _showSnackBar(
          context,
          "Xác thực sinh trắc học thành công!",
          Colors.green,
        );

        // Luồng chuẩn: Bạn sẽ lấy Token đã lưu ở lần đăng nhập trước từ Secure Storage ra để verify.
        // Tạm thời điều hướng vào ứng dụng:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } catch (e) {
      _showSnackBar(context, "Lỗi xác thực sinh trắc học: $e", Colors.red);
    }
  }

  // LOGIC 2: Xử lý đăng nhập mạng xã hội (Google)
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Người dùng chủ động hủy hộp thoại chọn tài khoản Google
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken =
          googleAuth.idToken; // Token dùng để gửi lên Backend

      if (!context.mounted) return;

      if (idToken != null) {
        _showSnackBar(
          context,
          "Đang xác thực tài khoản Google...",
          Colors.blue,
        );

        // TODO: Gửi idToken này sang AuthProvider để gọi API Backend xác thực
        // final errorMessage = await context.read<AuthProvider>().authenticateWithGoogle(idToken);

        // Giả lập điều hướng thành công sau khi backend verify token thành công
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      } else {
        _showSnackBar(
          context,
          "Không lấy được mã xác thực từ Google.",
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(context, "Đăng nhập Google thất bại: $e", Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final bool isLogin = authProvider.isLogin;
    final bool isLoading = authProvider.isLoading;
    final Color primaryColor = isLogin ? Colors.green : Colors.blue;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.eco, size: 100, color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  'EcoTrade',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin
                      ? 'Chào mừng bạn quay trở lại!'
                      : 'Tham gia cộng đồng tái chế ngay!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                if (!isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(
                      'Họ và tên',
                      Icons.person,
                      primaryColor,
                    ),
                    validator: (value) => value!.trim().isEmpty
                        ? 'Vui lòng nhập họ và tên'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(
                      'Địa chỉ',
                      Icons.location_on,
                      primaryColor,
                    ),
                    validator: (value) =>
                        value!.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _buildInputDecoration(
                      'Số điện thoại',
                      Icons.phone,
                      primaryColor,
                    ),
                    validator: (value) => value!.trim().length < 10
                        ? 'Số điện thoại không hợp lệ'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _buildInputDecoration(
                    'Email',
                    Icons.email,
                    primaryColor,
                  ),
                  validator: (value) {
                    if (value!.trim().isEmpty) return 'Vui lòng nhập email';
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value))
                      return 'Email không đúng định dạng';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleAuthenticate(context),
                  decoration: _buildInputDecoration(
                    'Mật khẩu',
                    Icons.lock,
                    primaryColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => value!.isEmpty || value.length < 6
                      ? 'Mật khẩu phải từ 6 ký tự'
                      : null,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () => _handleAuthenticate(context),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // GIAO DIỆN MỚI: Thanh phân cách "Hoặc đăng nhập bằng"
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Hoặc đăng nhập bằng',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade300, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // GIAO DIỆN MỚI: Khối chứa nút Đăng nhập bên thứ ba & Sinh trắc học
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nút Đăng nhập Google
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: isLoading
                            ? null
                            : () => _handleGoogleSignIn(context),
                        icon: const Icon(
                          Icons.g_mobiledata,
                          color: Colors.red,
                          size: 30,
                        ),
                        label: const Text(
                          'Google',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Nút Sinh trắc học (Chỉ hiển thị ở chế độ Đăng nhập, không hiện ở chế độ Đăng ký)
                    if (isLogin) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          onPressed: isLoading
                              ? null
                              : () => _handleBiometricAuth(context),
                          icon: Icon(
                            Icons.fingerprint,
                            color: primaryColor,
                            size: 26,
                          ),
                          label: const Text(
                            'Sinh trắc',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    _formKey.currentState?.reset();
                    context.read<AuthProvider>().toggleAuthMode();
                  },
                  child: Text(
                    isLogin
                        ? 'Chưa có tài khoản? Bấm vào đây để Đăng ký'
                        : 'Đã có tài khoản? Quay lại Đăng nhập',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAuthenticate(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

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
      _showSnackBar(context, errorMessage, Colors.red);
    } else {
      if (authProvider.isLogin) {
        _showSnackBar(context, "Đăng nhập thành công!", Colors.green);
        
        // KÍCH HOẠT HỆ THỐNG REAL-TIME NGAY KHI CÓ USER ID
        final socketService = context.read<SocketService>();
        final notifProvider = context.read<NotificationProvider>();
        final userId = authProvider.userId;

        if (userId != null) {
          socketService.connect();
          socketService.joinUserRoom(userId);    
          notifProvider.setupSocketListener(socketService); // 3. Gắn tai nghe cho App
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      } else {
        _showSnackBar(
          context,
          "Đăng ký thành công! Vui lòng đăng nhập.",
          Colors.blue,
        );
        authProvider.setLoginMode(true);
        _passwordController.clear();
      }
    }
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon,
    Color primaryColor, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
