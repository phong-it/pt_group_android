import 'dart:convert';
import 'dart:developer' as developer; // Sử dụng developer.log thay cho print

import '../models/chat_message_model.dart';
import '../services/socket_service.dart';

class ChatRepository {
  final SocketService _socketService;

  // Constructor Injection: Rất tốt để viết Unit Test sau này
  ChatRepository(this._socketService);

  void connect() {
    try {
      _socketService.connect();
      developer.log('Đang kết nối socket...', name: 'ChatRepository');
    } catch (e, stack) {
      developer.log(
        'Lỗi khi kết nối socket',
        error: e,
        stackTrace: stack,
        name: 'ChatRepository',
      );
    }
  }

  void joinRoom(String roomId) {
    if (roomId.isEmpty) {
      developer.log('Room ID rỗng, từ chối join', name: 'ChatRepository');
      return;
    }
    _socketService.joinRoom(roomId);
    developer.log('Đã gửi yêu cầu join room: $roomId', name: 'ChatRepository');
  }

  void sendMessage(ChatMessageModel message) {
    try {
      _socketService.sendMessage(message.toJson());
    } catch (e, stack) {
      developer.log(
        'Lỗi khi gửi tin nhắn',
        error: e,
        stackTrace: stack,
        name: 'ChatRepository',
      );
      // Ở đây có thể throw một CustomException để UI biết mà hiện Toast báo lỗi cho user
    }
  }

  void listenForMessages(Function(ChatMessageModel) onNewMessage) {
    // 1. CHỐNG DUPLICATE EVENT & MEMORY LEAK:
    // Hủy lắng nghe event cũ trước khi đăng ký mới.
    // Tránh tình trạng UI rebuild gọi hàm này nhiều lần làm user nhận 1 tin nhắn thành 2, 3 tin.
    _socketService.socket.off('receive_message');

    _socketService.socket.on('receive_message', (data) {
      try {
        // 2. KHẮC PHỤC LỖI TYPE ERROR KINH ĐIỂN:
        if (data == null) {
          developer.log('Nhận payload null từ socket', name: 'ChatRepository');
          return;
        }

        Map<String, dynamic> jsonMap;

        if (data is String) {
          // Nếu server gửi Stringified JSON
          jsonMap = jsonDecode(data) as Map<String, dynamic>;
        } else if (data is Map) {
          // Nếu server gửi JSON Object chuẩn
          jsonMap = Map<String, dynamic>.from(data);
        } else {
          throw FormatException(
            'Kiểu dữ liệu socket không hợp lệ: ${data.runtimeType}',
          );
        }

        final message = ChatMessageModel.fromJson(jsonMap);
        onNewMessage(message);
      } catch (e, stackTrace) {
        // 3. BẮT LỖI TẠI CHỖ: Không để crash app nếu 1 tin nhắn bị lỗi format
        developer.log(
          'Lỗi parse tin nhắn',
          error: e,
          stackTrace: stackTrace,
          name: 'ChatRepository',
        );
      }
    });
  }

  // Đổi tên thành dispose() cho chuẩn convention của Flutter
  void dispose() {
    // Luôn off các event đã đăng ký trước khi disconnect để dọn sạch bộ nhớ
    _socketService.socket.off('receive_message');
    _socketService.socket.disconnect();
    developer.log(
      'Đã dọn dẹp và ngắt kết nối ChatRepository',
      name: 'ChatRepository',
    );
  }
}
