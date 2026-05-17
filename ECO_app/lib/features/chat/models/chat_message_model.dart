import '../models/chat_message_model.dart';

// SENIOR ADD: Định nghĩa các kiểu thực thể tin nhắn hệ thống hỗ trợ
enum MessageType { text, image, system }

// SENIOR ADD: Khai báo các trạng thái vòng đời của một tin nhắn chuẩn thực tế
enum MessageStatus { sending, sent, failed }

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final MessageStatus status;
  final MessageType type; // SENIOR ADD: Thuộc tính phân loại tin nhắn công năng

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.status = MessageStatus
        .sent, // Mặc định tin nhắn từ DB load lên là đã gửi thành công
    this.type = MessageType
        .text, // Mặc định nếu không truyền là tin nhắn văn bản (text)
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
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Parse trạng thái gửi tin nhắn
    MessageStatus parsedStatus = MessageStatus.sent;
    if (json['status'] == 'sending') parsedStatus = MessageStatus.sending;
    if (json['status'] == 'failed') parsedStatus = MessageStatus.failed;

    // SENIOR DEFENSIVE CODE: Cơ chế phòng vệ phân tách kiểu dữ liệu an toàn.
    // Nếu tương lai Backend thêm type mới (ví dụ: 'video') mà Client bản cũ chưa cập nhật,
    // ứng dụng sẽ tự động fallback về dạng 'text' để không bị crash giao diện người dùng.
    MessageType parsedType = MessageType.text;
    if (json['type'] == 'image') parsedType = MessageType.image;
    if (json['type'] == 'system') parsedType = MessageType.system;

    return ChatMessageModel(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      status: parsedStatus,
      type: parsedType,
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
    };
  }
}
