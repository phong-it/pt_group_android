import 'dart:async'; // BẮT BUỘC: Để sử dụng StreamSubscription
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../services/socket_service.dart';

class ChatRepository {
  final SocketService _socketService;

  // SENIOR DESIGN: Dùng StreamSubscription để quản lý vòng đời lắng nghe dữ liệu
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  ChatRepository(this._socketService);

  void connect() {
    try {
      _socketService.connect();
      developer.log(
        'Đang gọi lệnh kết nối từ Service...',
        name: 'ChatRepository',
      );
    } catch (e, stack) {
      developer.log(
        'Lỗi kết nối',
        error: e,
        stackTrace: stack,
        name: 'ChatRepository',
      );
    }
  }

  void joinRoom(String roomId) {
    if (roomId.isEmpty) return;
    _socketService.joinRoom(roomId);
  }

  // SENIOR REFACTOR: Hàm sendMessage nhận thêm một callback trả về kết quả thành bại dạng bool
  void sendMessage(
    ChatMessageModel message, {
    required Function(bool isSuccess) onResult,
  }) {
    try {
      _socketService.sendMessage(
        message.toJson(),
        onAck: (response) {
          // Thỏa thuận cấu trúc payload với Backend Dev. Giả định chuẩn hóa: { "status": "success" }
          if (response is Map &&
              (response['status'] == 'success' || response['status'] == 'ok')) {
            onResult(true); // Gửi và lưu thành công
          } else {
            developer.log(
              'Server từ chối tin nhắn hoặc bị Timeout: $response',
              name: 'ChatRepository',
            );
            onResult(false); // Gửi thất bại
          }
        },
      );
    } catch (e, stack) {
      developer.log(
        'Lỗi phát sinh tại Repo khi gửi tin nhắn',
        error: e,
        stackTrace: stack,
        name: 'ChatRepository',
      );
      onResult(false);
    }
  }

  // SENIOR REFACTOR: Chuyển hoàn toàn sang lắng nghe bằng cơ chế Stream reactive
  void listenForMessages(Function(ChatMessageModel) onNewMessage) {
    // CHỐT CHẶN AN TOÀN: Hủy Subscription cũ trước khi đăng ký mới (Chống duplicate UI/Memory leak)
    _messageSubscription?.cancel();

    // Lắng nghe dữ liệu đổ về từ Stream sạch của SocketService
    _messageSubscription = _socketService.onMessage.listen((jsonMap) {
      try {
        // Dữ liệu qua Stream đã được ép kiểu Map<String, dynamic> ở Service
        final message = ChatMessageModel.fromJson(jsonMap);
        onNewMessage(message);
      } catch (e, stackTrace) {
        developer.log(
          'Lỗi parse tin nhắn từ Stream',
          error: e,
          stackTrace: stackTrace,
          name: 'ChatRepository',
        );
      }
    });

    developer.log(
      'Đã đăng ký lắng nghe Stream tin nhắn mới',
      name: 'ChatRepository',
    );
  }

  // SENIOR ADD: Hàm lấy lịch sử tin nhắn từ Remote DB
  // Thiết kế hàm trả về Future<List<...>> giúp Provider dễ dàng async/await
  Future<List<ChatMessageModel>> getChatHistory(
    String roomId, {
    int limit = 50,
  }) async {
    try {
      developer.log(
        'Đang tải lịch sử từ Firestore cho room: $roomId',
        name: 'ChatRepository',
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('chat_messages')
          .where('roomId', isEqualTo: roomId)
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      // Parse dữ liệu thô từ DB sang List Model của Dart
      final List<ChatMessageModel> historyMessages = snapshot.docs.map((doc) {
        return ChatMessageModel.fromJson({...doc.data(), 'id': doc.id});
      }).toList();

      return historyMessages;
    } catch (e, stackTrace) {
      developer.log(
        'Lỗi rò rỉ tại Firestore khi lấy history',
        error: e,
        stackTrace: stackTrace,
        name: 'ChatRepository',
      );
      // Rethrow để tầng Provider có thể bắt được lỗi và hiển thị lên UI nếu cần
      rethrow;
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
    _socketService.disconnect();
    developer.log(
      'Đã dọn dẹp và ngắt kết nối ChatRepository',
      name: 'ChatRepository',
    );
  }
}
