import 'package:flutter/material.dart';
import 'package:frontend/features/chat/services/socket_service.dart';
import 'package:frontend/features/notifications/providers/notification_provider.dart';
import 'package:frontend/features/profile/providers/user_provider.dart';
import '../models/chat_message_model.dart';
import '../repositories/chat_repository.dart';
import '../../../features/notifications/models/notification_model.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final NotificationProvider _notificationProvider;
  final UserProvider _userProvider;

  // SENIOR DESIGN: Khởi tạo một instance Uuid cố định (mục đích tối ưu bộ nhớ, tránh tạo đi tạo lại)
  static const _uuid = Uuid();

  // SENIOR ADD: Quản lý trạng thái kết nối hiện tại trong Provider
  SocketState _connectionState = SocketState.connected;

  // Getter giúp UI kiểm tra xem có đang phải trong trạng thái cố gắng kết nối lại không
  bool get isReconnecting => _connectionState == SocketState.reconnecting;

  // Sử dụng danh sách riêng tư để tránh can thiệp trực tiếp từ UI
  final List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  String? _activeRoomId;

  // SENIOR STATE MANAGEMENT: Quản lý trạng thái phân trang chặt chẽ
  bool _isLoading = false; // Loading cho lần đầu vào phòng
  bool _isFetchingMore = false; // Loading riêng cho việc cuộn lên tải thêm
  bool _hasMore = true; // Đánh dấu xem Server còn tin nhắn cũ để tải không

  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;

  // Sử dụng một tên public cho tham số truyền vào
  ChatProvider(
    this._chatRepository,
    this._notificationProvider, {
    required UserProvider userProvider, // Không dùng dấu _ ở đây
  }) : _userProvider = userProvider {
    _initSocketListener();
    _listenToConnectionStatus();
  }

  // SENIOR IMPLEMENTATION: Theo dõi biến động mạng để ra lệnh cập nhật UI
  void _listenToConnectionStatus() {
    _chatRepository.onConnectionStatus.listen((state) {
      _connectionState = state;
      notifyListeners(); // Báo cho UI biết để đóng/mở thanh trạng thái "Đang kết nối lại..."
    });
  }

  void _initSocketListener() {
    _chatRepository.connect();
    _chatRepository.listenForMessages((incomingMsg) {
      if (incomingMsg.roomId == _activeRoomId) {
        // Thu nạp tin nhắn đơn lẻ thời gian thực từ Socket
        _internalAddMessages([incomingMsg]);
      } else {
        _notificationProvider.addNotification(
          title: "Tin nhắn mới",
          body: incomingMsg.content,
          type: 'chat',
          roomId: incomingMsg.roomId,
        );
      }
    });
  }

  // SENIOR REFACTOR: Cập nhật lại hàm joinRoom để reset các biến phân trang về mặc định
  Future<void> joinRoom(String roomId) async {
    if (_activeRoomId == roomId) return;

    _activeRoomId = roomId;
    _messages.clear();
    _hasMore = true;
    _isFetchingMore = false;

    _isLoading = true;
    notifyListeners();

    _chatRepository.joinRoom(roomId);

    // Tải trang đầu tiên
    try {
      final List<ChatMessageModel> firstPage = await _chatRepository
          .getChatHistory(roomId, limit: 20);
      if (firstPage.length < 20) _hasMore = false;

      // SENIOR OPTIMIZATION: Đẩy mảng dữ liệu lịch sử vào bộ xử lý tập trung
      _internalAddMessages(firstPage);
    } catch (e) {
      debugPrint('Lỗi tải trang đầu: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Hàm nạp trang đầu tiên khi mở phòng chat (lấy 20 bản ghi)
  Future<void> _loadFirstPage(String roomId) async {
    try {
      final List<ChatMessageModel> firstPage = await _chatRepository
          .getChatHistory(roomId, limit: 20);
      _messages.addAll(firstPage);

      // Nếu trang đầu tiên trả về ít hơn giới hạn (20), nghĩa là DB đã hết sạch tin nhắn cũ
      if (firstPage.length < 20) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Lỗi tải trang đầu: $e');
    }
  }

  // SENIOR ADD: Hàm bốc thêm dữ liệu khi người dùng cuộn lên trên
  Future<void> loadMoreMessages(String roomId) async {
    if (_isFetchingMore || !_hasMore) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final DateTime? oldestMessageTime = _messages.isNotEmpty
          ? _messages.last.sentAt
          : null;
      final List<ChatMessageModel> nextPage = await _chatRepository
          .getChatHistory(roomId, limit: 20, lastSentAt: oldestMessageTime);

      if (nextPage.isEmpty || nextPage.length < 20) {
        _hasMore = false;
      }

      // SENIOR OPTIMIZATION: Tiếp tục đẩy danh sách phân trang vào bộ xử lý tập trung
      _internalAddMessages(nextPage);
    } catch (e) {
      debugPrint('Lỗi khi tải phân trang: $e');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // SENIOR REFACTOR: Hàm kích hoạt gửi tin nhắn kèm cơ chế ACK tường minh
  void sendMessage(String content, String roomId) {
    if (content.trim().isEmpty) return;

    final user = _userProvider.currentUser; // Lấy thông tin user hiện tại
    final String msgId = _uuid.v4(); // ID cố định cho vòng đời tin nhắn

    final newMsg = ChatMessageModel(
      id: msgId,
      roomId: roomId,
      senderId: user.id,
      senderName: user.name, // Lấy từ provider
      senderAvatar: user.avatar,
      content: content,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    _internalAddMessages([newMsg]);

    _chatRepository.sendMessage(
      newMsg,
      onResult: (isSuccess) {
        // Dùng ID để update chính xác tin nhắn đó, không tạo mới
        _updateMessageStatus(
          msgId,
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

  void _internalAddMessages(List<ChatMessageModel> incoming) {
    bool hasChanged = false;

    for (var msg in incoming) {
      final index = _messages.indexWhere((m) => m.id == msg.id);

      if (index != -1) {
        // Nếu đã tồn tại (ví dụ: đang ở trạng thái sending), chỉ cập nhật nếu trạng thái khác biệt
        if (_messages[index].status != msg.status) {
          _messages[index] = msg;
          hasChanged = true;
        }
      } else {
        _messages.add(msg);
        hasChanged = true;
      }
    }

    if (hasChanged) {
      _messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      notifyListeners();
    }
  }

  // SENIOR ADD: Hàm dùng để cập nhật trạng thái của một phần tử trong mảng Immutable an toàn
  void _updateMessageStatus(String messageId, MessageStatus newStatus) {
    final int index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: newStatus);
      notifyListeners();
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
      status: MessageStatus.sending,
      senderName: '',
      senderAvatar: '', // Đưa về trạng thái chờ gửi
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
