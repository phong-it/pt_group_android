import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Khởi tạo 2 công cụ của Firebase: Auth (Đăng nhập) và Firestore (Database)
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// 1. HÀM ĐĂNG KÝ TÀI KHOẢN MỚI
  Future<String?> signUp({
    required String email, 
    required String password, 
    required String name,
    required String address,
    required String phone, 
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      
      // ĐẨY DỮ LIỆU LÊN THEO CẤU TRÚC MỚI CỦA PHONG
      await _firestore.collection('users').doc(uid).set({
        'authId': uid,
        'name': name,
        'email': email,
        'avatar': 'https://ui-avatars.com/api/?name=${name.replaceAll(' ', '+')}&background=random',
        'address': address,
        'phone': phone, 
        'role': 'buyer', // Mặc định khi mới tạo là buyer (người mua)
        'eco_points': 0, 
      });

      await _auth.signOut();
      return null; 
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'Mật khẩu quá yếu (phải từ 6 ký tự trở lên).';
      if (e.code == 'email-already-in-use') return 'Email này đã được sử dụng!';
      return e.message;
    } catch (e) {
      return 'Đã xảy ra lỗi: $e';
    }
  }

  // 2. HÀM ĐĂNG NHẬP
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Thành công
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Email hoặc mật khẩu không chính xác.';
      }
      return e.message;
    } catch (e) {
      return 'Đã xảy ra lỗi: $e';
    }
  }

  // 3. HÀM ĐĂNG XUẤT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}