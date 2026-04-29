class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime sentAt;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.sentAt,
  });

  // PHẢI CÓ: Chuyển từ JSON của Socket về Object Dart
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      // Chuyển string ISO8601 từ Server về DateTime
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
    );
  }

  // PHẢI CÓ: Chuyển từ Object Dart sang Map để gửi lên Socket
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'sentAt': sentAt.toIso8601String(), // Gửi dưới dạng string chuẩn
    };
  }
}
