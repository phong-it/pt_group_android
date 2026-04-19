import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/shared/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // HÀM LẤY DỮ LIỆU
  Future<void> fetchUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _isLoading = true;

    try {
      // Tìm document trong bảng 'users' có ID trùng với authId của Firebase
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        // Dùng đúng hàm fromFirestore mà bạn đã viết
        _user = UserModel.fromFirestore(doc);
      } else {
        print('Không tìm thấy dữ liệu user trên Firestore');
      }
    } catch (e) {
      print('Lỗi khi tải thông tin: $e');
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
}