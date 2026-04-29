// lib/modules/chat/repositories/chat_repository.dart

import '../models/chat_message_model.dart';
import '../services/socket_service.dart';

class ChatRepository {
  final SocketService _socketService;

  // Inject SocketService vào Repository
  ChatRepository(this._socketService);

  // Khởi tạo kết nối
  void connect() {
    _socketService.connect();
  }

  // Vào phòng chat
  void joinRoom(String roomId) {
    _socketService.joinRoom(roomId);
  }

  // Xử lý logic gửi tin nhắn
  void sendMessage(ChatMessageModel message) {
    // Repository nhận Object từ Provider, chuyển thành JSON để Service gửi đi
    _socketService.sendMessage(message.toJson());
  }

  // Lắng nghe tin nhắn mới và chuyển đổi JSON -> Object Dart
  void listenForMessages(Function(ChatMessageModel) onNewMessage) {
    _socketService.socket.on('receive_message', (data) {
      // Dữ liệu thô từ mạng về sẽ được "dịch" ra Model tại đây
      final message = ChatMessageModel.fromJson(data);
      onNewMessage(message);
    });
  }
}
