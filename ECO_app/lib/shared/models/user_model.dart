import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // ID của document
  final String authId; // Đổi từ uid
  final String name; // Đổi từ full_name
  final String email;
  final String avatar; // Đổi từ avatar_url
  final String address;
  final String phone; // Mới thêm
  final String role; // Mới thêm
  final int ecoPoints;

  UserModel({
    required this.id,
    required this.authId,
    required this.name,
    required this.email,
    required this.avatar,
    required this.address,
    required this.phone,
    required this.role,
    required this.ecoPoints,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      authId: data['authId'] ?? '',
      name: data['name'] ?? 'Người dùng',
      email: data['email'] ?? '',
      avatar: data['avatar'] ?? 'https://ui-avatars.com/api/?name=User',
      address: data['address'] ?? 'Chưa cập nhật',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'buyer', // Mặc định là người mua
      ecoPoints: (data['eco_points'] ?? 0).toInt(), // Giữ tạm để phòng hờ
    );
  }
}