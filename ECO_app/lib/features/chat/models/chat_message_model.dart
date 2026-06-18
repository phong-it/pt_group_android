import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message_model.dart';

// SENIOR ADD: Định nghĩa các kiểu thực thể tin nhắn hệ thống hỗ trợ
enum MessageType { text, image, system }

// SENIOR ADD: Khai báo các trạng thái vòng đời của một tin nhắn chuẩn thực tế
enum MessageStatus { sending, sent, failed }

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName; // MỚI: Tên người gửi để hiển thị ngay
  final String senderAvatar; // MỚI: Avatar người gửi
  final String content;
  final DateTime sentAt;
  final MessageStatus status;
  final MessageType type;

  // Helper property: Giúp UI quyết định hiển thị bên trái hay phải
  bool isMe(String currentUserId) => senderId == currentUserId;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName, // Thêm vào constructor
    required this.senderAvatar, // Thêm vào constructor
    required this.content,
    required this.sentAt,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
  });

  // SENIOR DESIGN PATTERN: Cập nhật hàm copyWith để hỗ trợ thay đổi loại tin nhắn nếu cần
  ChatMessageModel copyWith({MessageStatus? status, MessageType? type}) {
    return ChatMessageModel(
      id: id,
      roomId: roomId,
      senderId: senderId,
      content: content,
      sentAt: sentAt,
      status: status ?? this.status,
      type: type ?? this.type,
      senderName: senderName,
      senderAvatar: senderAvatar,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Unknown', // Mặc định nếu chưa có
      senderAvatar: json['senderAvatar'] ?? '',
      content: json['content'] ?? '',
      sentAt: json['sentAt'] is Timestamp
          ? (json['sentAt'] as Timestamp).toDate()
          : DateTime.now(), // Xử lý tốt hơn với kiểu Timestamp của Firestore
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'status': status.name,
      'type': type
          .name, // Chuyển enum sang String ('text', 'image', 'system') để lưu lên DB/Socket
      'senderName': senderName,
      'senderAvatar': senderAvatar,
    };
  }
}
