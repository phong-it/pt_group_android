import 'package:flutter/material.dart';
import 'package:frontend/features/notifications/providers/notification_provider.dart';
import '../models/chat_message_model.dart';
import '../repositories/chat_repository.dart';
import '../../../features/notifications/models/notification_model.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final NotificationProvider _notificationProvider;

  // SENIOR DESIGN: Khởi tạo một instance Uuid cố định (mục đích tối ưu bộ nhớ, tránh tạo đi tạo lại)
  static const _uuid = Uuid();

  // Sử dụng danh sách riêng tư để tránh can thiệp trực tiếp từ UI
  final List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  String? _activeRoomId;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ChatProvider(this._chatRepository, this._notificationProvider) {
    _initSocketListener();
  }

  // --- 1. QUẢN LÝ SOCKET LISTENER ---
  void _initSocketListener() {
    _chatRepository.connect();
    _chatRepository.listenForMessages((incomingMsg) {
      // Logic xử lý thông báo
      if (incomingMsg.roomId == _activeRoomId) {
        // Đang trong phòng: Chỉ thêm tin nhắn vào UI
        _internalAddMessage(incomingMsg);
      } else {
        // ĐANG Ở NGOÀI: Đẩy thông báo vào NotificationProvider
        _notificationProvider.addNotification(
          title: "Tin nhắn mới",
          body: incomingMsg.content,
          type: 'chat',
          roomId: incomingMsg.roomId, // Truyền ID để lát nữa click điều hướng
        );
      }
    });
  }

  // --- 2. LOGIC VÀO PHÒNG CHAT ---
  Future<void> joinRoom(String roomId) async {
    if (_activeRoomId == roomId) return;

    _activeRoomId = roomId;
    _messages.clear();

    _isLoading = true; // Bật loading để UI hiển thị Shimmer/Spinner chuẩn Zalo
    notifyListeners();

    _chatRepository.joinRoom(roomId);

    // Gọi hàm tải lịch sử mới đã được tối ưu
    await loadMessagesFromRepository(roomId);

    _isLoading = false; // Tải xong thì tắt loading
    notifyListeners();
  }

  // SENIOR REFACTOR: Hàm kích hoạt gửi tin nhắn kèm cơ chế ACK tường minh
  void SendMessage(String content, String roomId, String userId) {
    if (content.trim().isEmpty) return;

    final String secureMessageId = _uuid.v4();

    final newMsg = ChatMessageModel(
      id: secureMessageId,
      roomId: roomId,
      senderId: userId,
      content: content,
      sentAt: DateTime.now(),
      status: MessageStatus.sending, // Bước 1: Đánh dấu đang gửi
    );

    // Kích hoạt Optimistic UI ngay lập tức để người dùng không cảm nhận độ trễ hình ảnh
    _internalAddMessage(newMsg);

    // Bước 2: Bắn dữ liệu xuống Repo và đợi lắng nghe ACK kết quả từ Server/Timeout
    _chatRepository.sendMessage(
      newMsg,
      onResult: (isSuccess) {
        // Bước 3: Cập nhật chính xác trạng thái dựa vào phản hồi bắt tay 1-1
        _updateMessageStatus(
          secureMessageId,
          isSuccess ? MessageStatus.sent : MessageStatus.failed,
        );
      },
    );
  }

  // SENIOR REFACTOR & PERFORMANCE FIX:
  // 1. Chỉ gọi dữ liệu thông qua cầu nối Repository.
  // 2. Vá lỗi tối ưu hiệu năng sắp xếp mảng.
  Future<void> loadMessagesFromRepository(String roomId) async {
    try {
      // Gọi qua Repo thay vì tự đi đêm với Firestore
      final List<ChatMessageModel> historyMessages = await _chatRepository
          .getChatHistory(roomId);

      // CHẶN BUG HIỆU NĂNG: Gộp dữ liệu một cách thông minh
      bool hasNewData = false;
      for (var msg in historyMessages) {
        final bool isDuplicate = _messages.any(
          (existing) => existing.id == msg.id,
        );
        if (!isDuplicate) {
          _messages.add(msg); // Thêm thẳng vào mảng, TUYỆT ĐỐI không sort ở đây
          hasNewData = true;
        }
      }

      // CHỐT HẠ: Chỉ sắp xếp mảng ĐÚNG 1 LẦN DUY NHẤT sau khi nạp xong toàn bộ 50 tin nhắn
      if (hasNewData) {
        _messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      }
    } catch (e) {
      debugPrint('Senior Log - Provider không thể nạp tin nhắn: $e');
      // Tầng này có thể set trạng thái _hasError = true để UI hiển thị nút "Tải lại trang"
    }
  }

  // SENIOR CLEAN-UP: Hàm bổ sung tin nhắn từ stream hoặc từ tối ưu cục bộ
  void _internalAddMessage(ChatMessageModel msg) {
    final int existingIndex = _messages.indexWhere(
      (existing) => existing.id == msg.id,
    );

    if (existingIndex != -1) {
      // SENIOR ARCHITECTURE: Nếu tin nhắn đã tồn tại trên UI (do chính thiết bị này gửi đi bằng Optimistic),
      // chúng ta tuyệt đối KHÔNG ghi đè dữ liệu thô từ luồng Broadcast về đây nữa.
      // Trạng thái thành bại của tin nhắn tự gửi phải được định đoạt ĐỘC QUYỀN bởi hàm ACK bên dưới.
      return;
    }

    // Nếu tin nhắn chưa có (Tin nhắn từ đối phương gửi sang, hoặc từ thiết bị khác đồng bộ về)
    _messages.insert(0, msg);
    _messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    notifyListeners();
  }

  // SENIOR ADD: Hàm dùng để cập nhật trạng thái của một phần tử trong mảng Immutable an toàn
  void _updateMessageStatus(String messageId, MessageStatus newStatus) {
    final int index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      // Tạo một bản sao object mới với trạng thái mới bằng hàm copyWith
      _messages[index] = _messages[index].copyWith(status: newStatus);
      notifyListeners(); // Chỉ render lại vùng bong bóng tin nhắn đó
    }
  }

  // SENIOR ADD: Hàm xử lý tái gửi tin nhắn bị lỗi
  void retrySendMessage(String messageId) {
    // 1. Tìm vị trí tin nhắn lỗi trong danh sách bộ nhớ cục bộ
    final int index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final failedMsg = _messages[index];

    // CHẶN BUG ĐỒNG BỘ: Chỉ cho phép gửi lại nếu tin nhắn đó thực sự đang ở trạng thái lỗi
    if (failedMsg.status != MessageStatus.failed) return;

    // 2. SENIOR UX TOUCH: Tạo một Instance mới, cập nhật trạng thái về 'sending'
    // đồng thời làm mới thời gian 'sentAt' thành ngay bây giờ để tin nhắn tự động nhảy lên đầu UI
    _messages[index] = ChatMessageModel(
      id: failedMsg.id,
      roomId: failedMsg.roomId,
      senderId: failedMsg.senderId,
      content: failedMsg.content,
      sentAt: DateTime.now(), // Làm mới thời gian phát hành tin nhắn
      status: MessageStatus.sending, // Đưa về trạng thái chờ gửi
    );

    // 3. Sắp xếp lại mảng cục bộ vì một phần tử vừa thay đổi mốc thời gian
    _messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    notifyListeners(); // Render lại UI hiển thị vòng xoay chờ mạng

    // 4. Bắn lại vào tầng Repository để thử vận may kết nối một lần nữa
    _chatRepository.sendMessage(
      _messages[index],
      onResult: (isSuccess) {
        // 5. Khớp lệnh trạng thái dựa trên kết quả bắt tay ACK mới của Server
        _updateMessageStatus(
          failedMsg.id,
          isSuccess ? MessageStatus.sent : MessageStatus.failed,
        );
      },
    );
  }

  // Xóa cache khi logout hoặc không dùng nữa
  void clearState() {
    _messages.clear();
    _activeRoomId = null;
    notifyListeners();
  }
}
