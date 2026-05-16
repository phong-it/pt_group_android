// SENIOR ADD: Khai báo các trạng thái vòng đời của một tin nhắn chuẩn thực tế
enum MessageStatus { sending, sent, failed }

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final MessageStatus status;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.status = MessageStatus
        .sent, // Mặc định tin nhắn từ DB load lên là đã gửi thành công
  });

  // SENIOR DESIGN PATTERN: Hàm sao chép đối tượng, cực kỳ quan trọng để cập nhật trạng thái trong mảng Immutable
  ChatMessageModel copyWith({MessageStatus? status}) {
    return ChatMessageModel(
      id: id,
      roomId: roomId,
      senderId: senderId,
      content: content,
      sentAt: sentAt,
      status: status ?? this.status,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Parse trạng thái từ String (Server) sang Enum (Dart)
    MessageStatus parsedStatus = MessageStatus.sent;
    if (json['status'] == 'sending') parsedStatus = MessageStatus.sending;
    if (json['status'] == 'failed') parsedStatus = MessageStatus.failed;

    return ChatMessageModel(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      status: parsedStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'status': status
          .name, // Chuyển enum về String ('sending', 'sent', 'failed') để gửi lên Socket
    };
  }
}
