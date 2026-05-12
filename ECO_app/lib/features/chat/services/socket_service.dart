import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/network/api_config.dart';

class SocketService {
  late IO.Socket socket;

  void connect() {
    print("Đang kết nối Socket tới: ${ApiConfig.socketUrl}");

    socket = IO.io(
      ApiConfig.socketUrl, // <-- Dùng biến dynamic ở đây
      IO.OptionBuilder()
          .setTransports(['websocket']) // Bắt buộc để chạy mượt trên Flutter
          .enableAutoConnect() // Tự động kết nối lại nếu rớt mạng
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('Đã kết nối Socket thành công!');
    });

    socket.onConnectError((data) => print('Lỗi kết nối Socket: $data'));
  }

  void joinRoom(String roomId) => socket.emit('join_room', roomId);

  void sendMessage(Map<String, dynamic> data) =>
      socket.emit('send_message', data);

  // Stream để lắng nghe tin nhắn mới từ server
  Stream<Map<String, dynamic>> get onMessage {
    return Stream.fromIterable(
      [],
    ).asyncExpand((_) async* {}); // Logic Stream cơ bản
    // Trong thực tế, bạn sẽ dùng StreamController để quản lý việc này
  }
}
