import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/socket_service.dart';
import '../repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => _messages;

  late final ChatRepository _chatRepository;

  ChatProvider() {
    // Khởi tạo Service và truyền vào Repository
    final socketService = SocketService();
    _chatRepository = ChatRepository(socketService);

    _initChat();
  }

  void _initChat() {
    _chatRepository.connect();

    // Provider chỉ việc nhận Model sạch sẽ từ Repository và hiển thị
    _chatRepository.listenForMessages((incomingMsg) {
      addMessage(incomingMsg);
    });
  }

  void addMessage(ChatMessageModel msg) {
    _messages.insert(0, msg);
    notifyListeners();
  }

  void handleSendMessage(
    String id,
    String content,
    String roomId,
    String userId,
  ) {
    final newMsg = ChatMessageModel(
      id: id,
      content: content,
      roomId: roomId,
      senderId: userId,
      sentAt: DateTime.now(),
    );

    // Bắn thẳng Model sang cho Repository lo liệu
    _chatRepository.sendMessage(newMsg);

    // Cập nhật lên màn hình ngay lập tức
    addMessage(newMsg);
  }
}
