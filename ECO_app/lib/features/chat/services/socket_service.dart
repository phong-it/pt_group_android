import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/network/api_config.dart';

class SocketService {
  IO.Socket? _socket; // Không dùng late, dùng nullable để an toàn

  // StreamController để quản lý tin nhắn (thay vì placeholder cũ)
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  // Getter an toàn: Nếu chưa kết nối mà truy cập sẽ báo lỗi rõ ràng thay vì crash âm thầm
  IO.Socket get socket {
    if (_socket == null) {
      throw Exception(
        "SocketService: Chưa gọi connect(). Hãy đảm bảo connect() được gọi khi khởi tạo app.",
      );
    }
    return _socket!;
  }

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null && _socket!.connected)
      return; // Tránh kết nối trùng lặp

    print("🔌 Đang kết nối Socket tới: ${ApiConfig.socketUrl}");

    _socket = IO.io(
      ApiConfig.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('✅ Đã kết nối Socket thành công!');
    });

    _socket!.on('new_message', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.onConnectError((data) => print('❌ Lỗi kết nối Socket: $data'));
    _socket!.onDisconnect((_) => print('🔌 Đã ngắt kết nối Socket'));
  }

  void joinRoom(String roomId) => _socket?.emit('join_room', roomId);

  void sendMessage(Map<String, dynamic> data) =>
      _socket?.emit('send_message', data);

  void dispose() {
    _socket?.dispose();
    _messageController.close();
  }
}
