import 'dart:developer'
    as developer; // SENIOR ADD: Dùng thư viện chuẩn để quản lý log hệ thống
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/shared/models/user_model.dart';
import '../service/profile_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  final ProfileService _profileService = ProfileService();

  // GIỮ NGUYÊN: Getter cũ để các màn hình Profile, Edit hiện tại không bị lỗi biên dịch
  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // ===========================================================================
  // SENIOR ADD: KHẮC PHỤC LỖI "UNDEFINED GETTER" CHO CHAT_PROVIDER
  // ===========================================================================
  /// Getter trả về dữ liệu User không-được-null.
  /// Ép buộc hệ thống phải kiểm soát chặt chẽ trạng thái đăng nhập trước khi cho phép Chat/Gửi tin.
  UserModel get currentUser {
    if (_user == null) {
      developer.log(
        'CRITICAL CRASH PREVENTED: Một tính năng (như Chat) đã cố truy cập User trước khi dữ liệu được tải từ Firestore!',
        name: 'UserProvider',
        error: StateError('User data is null'),
      );
      // Ném ra một lỗi có cấu trúc rõ ràng thay vì để ứng dụng crash ngầm không rõ nguyên nhân
      throw StateError(
        'Xác thực thất bại: Vui lòng đợi dữ liệu tải xong hoặc thực hiện đăng nhập lại.',
      );
    }
    return _user!;
  }

  // HÀM LẤY DỮ LIỆU
  Future<void> fetchUserData() async {
    final currentUserAuth = FirebaseAuth.instance.currentUser;
    if (currentUserAuth == null) return;

    _isLoading = true;
    // Bổ sung notifyListeners() ở đây nếu bạn muốn UI hiển thị vòng xoay loading ngay khi bắt đầu gọi API
    notifyListeners();

    try {
      // Tìm document trong bảng 'users' có ID trùng với authId của Firebase
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserAuth.uid)
          .get();

      if (doc.exists) {
        // Dùng đúng hàm fromFirestore mà bạn đã viết
        _user = UserModel.fromFirestore(doc);
      } else {
        developer.log(
          'Không tìm thấy dữ liệu user trên Firestore',
          name: 'UserProvider',
        );
      }
    } catch (e, stack) {
      developer.log(
        'Lỗi khi tải thông tin người dùng',
        error: e,
        stackTrace: stack,
        name: 'UserProvider',
      );
    } finally {
      _isLoading = false;
      notifyListeners(); // Kích hoạt làm mới giao diện
    }
  }

  // HÀM DỌN DẸP KHI ĐĂNG XUẤT
  void clearUserData() {
    _user = null;
    notifyListeners();
  }

  // GIỮ NGUYÊN: Hàm edit profile của bạn để không làm lỗi code UI cũ
  Future<void> edit_profile({
    required String name,
    required String phone,
    required String address,
    required String role,
  }) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    String? error = await _profileService.edit_profile(
      uid: _user!.authId,
      name: name,
      phone: phone,
      address: address,
      role: role,
    );

    if (error == null) {
      _user = _user!.copyWith(
        name: name,
        phone: phone,
        address: address,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
    } else {
      _isLoading = false;
      notifyListeners();
      throw error;
    }
  }
}
