import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/service/auth_service.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> edit_profile({
    required String uid,
    required String name,
    required String phone,
    required String address,
    required String role,
    String? avatarUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'phone': phone,
        'address': address,
        'role': role,
        if (avatarUrl != null) 'avatar': avatarUrl,
      });
      return null;
    } catch (e) {
      return 'lỗi khi chỉnh sữa thông tin: $e';
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
  try {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  } catch (e) {
    print('Lỗi khi lấy thông tin: $e');
    return null;
  }
}


}
