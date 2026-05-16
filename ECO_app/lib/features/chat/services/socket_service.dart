import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/network/api_config.dart';

class SocketService {
  IO.Socket? _socket;

  // StreamController quản lý luồng tin nhắn đi vào app
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  // Thêm vào cùng chỗ với _messageController
  final _orderStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onOrderStatusChanged =>
      _orderStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    print("🔌 Đang kết nối Socket tới: ${ApiConfig.socketUrl}");

    _socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) => print('✅ Đã kết nối Socket thành công!'));

    // SENIOR FIX: Sửa tên Event thành 'receive_message' cho đồng bộ với Repo
    // Đồng thời kiểm tra data null trước khi push vào Stream công khai
    _socket!.on('receive_message', (data) {
      if (data != null) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    // SENIOR ADD: Lắng nghe sự kiện đổi trạng thái đơn hàng và đẩy vào Stream riêng
    _socket!.on('order_status_changed', (data) {
      if (data != null) {
        _orderStatusController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onConnectError((data) => print('❌ Lỗi kết nối Socket: $data'));
    _socket!.onDisconnect((_) => print('🔌 Đã ngắt kết nối Socket'));
  }

  // Các hàm tương tác được đóng gói tường minh (Encapsulation)
  void joinRoom(String roomId) => _socket?.emit('join_room', roomId);

  // SENIOR REFACTOR: Nâng cấp hàm sendMessage nhận thêm một callback để xử lý ACK
  void sendMessage(
    Map<String, dynamic> data, {
    required Function(dynamic) onAck,
  }) {
    bool hasTriggeredAck = false;

    // SENIOR DESIGN PATTERN: Cơ chế phòng vệ Client-side Timeout.
    // Nếu trong vòng 5 giây mà Server không phản hồi ACK (do lag, sập nguồn, mất mạng...),
    // Client sẽ chủ động kích hoạt trạng thái lỗi để bảo vệ trải nghiệm người dùng, tránh xoay vô tận.
    final timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!hasTriggeredAck) {
        hasTriggeredAck = true;
        onAck({
          'status': 'timeout',
          'message': 'Không nhận được phản hồi từ máy chủ.',
        });
      }
    });

    // CHỐT CHẶN AN TOÀN: Nếu kiểm tra thấy socket đang ngắt kết nối, báo thất bại luôn
    if (_socket == null || !_socket!.connected) {
      timeoutTimer.cancel();
      hasTriggeredAck = true;
      onAck({'status': 'error', 'message': 'Mất kết nối mạng Socket.'});
      return;
    }

    try {
      // SENIOR IMPLEMENTATION: Thay thế .emit bằng .emitWithAck chuẩn socket.io toàn cầu
      _socket!.emitWithAck(
        'send_message',
        data,
        ack: (ackData) {
          // Nếu Server phản hồi kịp thời trước 5 giây, hủy bộ đếm timeout ngay lập tức
          if (!hasTriggeredAck) {
            timeoutTimer.cancel();
            hasTriggeredAck = true;
            onAck(ackData);
          }
        },
      );
    } catch (e) {
      if (!hasTriggeredAck) {
        timeoutTimer.cancel();
        hasTriggeredAck = true;
        onAck({'status': 'error', 'message': e.toString()});
      }
    }
  }

  // SENIOR ADD: Cung cấp hàm ngắt kết nối an toàn, thay vì để Repo tự can thiệp vào nội bộ socket
  void disconnect() {
    _socket?.disconnect();
  }

  void dispose() {
    _socket?.dispose();
    _messageController.close();
    _orderStatusController.close(); // Đóng controller mới khi dispose
  }
}
