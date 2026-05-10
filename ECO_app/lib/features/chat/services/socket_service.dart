import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    // Lưu ý: Dùng 10.0.2.2 nếu dùng Emulator Android, hoặc IP thật của máy tính
    socket = IO.io(
      'http://172.16.0.172:3001',
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );
    socket.connect();
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
