import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '', // Đã đổi từ user_id
      title: data['title'] ?? 'Thông báo',
      body: data['body'] ?? '',
      isRead: data['isRead'] ?? false, // Đã đổi từ is_read
      createdAt: data['createdAt'] != null // Đã đổi từ created_at
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }
}