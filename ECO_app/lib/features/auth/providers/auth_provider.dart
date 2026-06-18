import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // THÊM IMPORT NÀY
import 'package:cloud_firestore/cloud_firestore.dart'; // THÊM IMPORT NÀY
import 'package:google_sign_in/google_sign_in.dart'; // THÊM IMPORT NÀY
import '../service/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  // Khởi tạo Firestore để lưu dữ liệu
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        if (name == null ||
            name.isEmpty ||
            address == null ||
            address.isEmpty) {
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

  // ===== THÊM MỚI HÀM NÀY ĐỂ XỬ LÝ GOOGLE SIGN IN =====
  Future<String?> authenticateWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null; // Người dùng hủy đăng nhập
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 1. Đăng nhập vào Firebase Auth bằng credential của Google
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // 2. KIỂM TRA VÀ LƯU DỮ LIỆU VÀO FIRESTORE (QUAN TRỌNG)
        // Kiểm tra xem user này đã có trong bảng 'users' chưa
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Lần đầu đăng nhập bằng Google -> Tạo document mới giống cấu trúc của Phong
          await _firestore.collection('users').doc(user.uid).set({
            'authId': user.uid,
            'name': user.displayName ?? 'Người dùng Google',
            'email': user.email ?? '',
            'avatar':
                user.photoURL ??
                'https://ui-avatars.com/api/?name=${(user.displayName ?? 'User').replaceAll(' ', '+')}&background=random',
            'address': 'Chưa cập nhật',
            'phone': 'Chưa cập nhật',
            'role': 'buyer',
            'eco_points': 0,
          });
        }
        // Nếu đã tồn tại rồi thì không cần làm gì, dữ liệu cũ vẫn giữ nguyên
      }

      _isLoading = false;
      notifyListeners();
      return null; // Thành công không có lỗi
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Đăng nhập Google thất bại: $e';
    }
  }

  // THÊM 2 GETTER NÀY ĐỂ UI DỄ DÀNG LẤY TOKEN & UID
  Future<String?> getUserToken() async {
    return await _authService.getIdToken();
  }

  String? get userId => _authService.currentUserId;
}
