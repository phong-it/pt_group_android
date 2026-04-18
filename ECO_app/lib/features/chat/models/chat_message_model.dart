import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime sentAt;

  ChatMessageModel({
    required this.id, required this.roomId,
    required this.senderId, required this.content, required this.sentAt,
  });

  // Chuyển từ Map trên Firebase về Object Dart
  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessageModel(
      id: docId,
      roomId: map['roomId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      // Lưu ý: Firebase trả về kiểu Timestamp, phải chuyển sang DateTime
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Chuyển từ Object Dart thành Map để đẩy lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'sentAt': FieldValue.serverTimestamp(), // Dùng thời gian server, không dùng máy khách
    };
  }
}