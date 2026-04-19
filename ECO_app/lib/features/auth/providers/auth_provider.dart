import 'package:flutter/material.dart';
import '../service/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;

  bool get isLogin => _isLogin;
  bool get isLoading => _isLoading;

  // Đổi trạng thái giữa Đăng nhập / Đăng ký
  void toggleAuthMode() {
    _isLogin = !_isLogin;
    notifyListeners();
  }

  // Set cứng trạng thái (dùng khi đăng ký thành công chuyển về đăng nhập)
  void setLoginMode(bool value) {
    _isLogin = value;
    notifyListeners();
  }

  // Xử lý logic chung cho cả SignIn và SignUp
  Future<String?> authenticate({
    required String email,
    required String password,
    String? name,
    String? address,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners(); // Cập nhật UI hiển thị vòng quay loading

    String? errorMessage;

    try {
      if (_isLogin) {
        errorMessage = await _authService.signIn(
          email: email,
          password: password,
        );
      } else {
        if (name == null || name.isEmpty || address == null || address.isEmpty) {
          errorMessage = "Vui lòng nhập đầy đủ Họ tên và Địa chỉ!";
        } else {
          errorMessage = await _authService.signUp(
            email: email,
            password: password,
            name: name,
            address: address,
            phone: phone ?? '',
          );
        }
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Tắt vòng quay loading
    }

    return errorMessage;
  }
}