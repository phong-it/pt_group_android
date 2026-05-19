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

  Stream<SocketState> get onConnectionStatus => _socketService.onStatusChanged;

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

  // SENIOR REFACTOR: Nâng cấp hàm lấy lịch sử hỗ trợ Phân trang (Pagination)
  // Nhận vào mốc thời gian `lastSentAt` của tin nhắn cũ nhất hiện tại trên UI
  Future<List<ChatMessageModel>> getChatHistory(
    String roomId, {
    int limit =
        20, // SENIOR CHOSEN: Lấy 20 tin mỗi trang theo đúng yêu cầu Story
    DateTime? lastSentAt,
  }) async {
    try {
      developer.log(
        'Tải trang tiếp theo cho room: $roomId. Mốc thời gian: $lastSentAt',
        name: 'ChatRepository',
      );

      // Khởi tạo query cơ bản ban đầu
      var query = FirebaseFirestore.instance
          .collection('chat_messages')
          .where('roomId', isEqualTo: roomId)
          .orderBy('sentAt', descending: true)
          .limit(limit);

      // SENIOR INSTRUCTION: Nếu có mốc thời gian cũ, sử dụng startAfter để Firestore
      // bỏ qua các tin nhắn đã có trên UI và lấy tiếp các tin nhắn cũ hơn nữa.
      if (lastSentAt != null) {
        query = query.startAfter([Timestamp.fromDate(lastSentAt)]);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e, stackTrace) {
      developer.log(
        'Lỗi phân trang tại Firestore',
        error: e,
        stackTrace: stackTrace,
        name: 'ChatRepository',
      );
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
