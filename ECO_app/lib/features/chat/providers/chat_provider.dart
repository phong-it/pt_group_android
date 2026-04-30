import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;

  // Sử dụng danh sách riêng tư để tránh can thiệp trực tiếp từ UI
  final List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  String? _activeRoomId;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ChatProvider(this._chatRepository) {
    _initSocketListener();
  }

  // --- 1. QUẢN LÝ SOCKET LISTENER ---
  void _initSocketListener() {
    _chatRepository.connect();
    _chatRepository.listenForMessages((incomingMsg) {
      // SENIOR CHECK: Chỉ chấp nhận tin nhắn nếu:
      // 1. Nó thuộc về phòng người dùng đang mở (_activeRoomId)
      // 2. Nó chưa tồn tại trong danh sách (Tránh trùng lặp do Socket/Firestore cùng đẩy về)
      if (incomingMsg.roomId == _activeRoomId) {
        _internalAddMessage(incomingMsg);
      }
    });
  }

  // --- 2. LOGIC VÀO PHÒNG CHAT ---
  Future<void> joinRoom(String roomId) async {
    // Nếu đang ở đúng phòng này rồi thì không làm gì cả
    if (_activeRoomId == roomId) return;

    _activeRoomId = roomId;

    // Reset trạng thái để chuẩn bị cho phòng mới
    _messages.clear();
    // _isLoading = true;
    notifyListeners();

    // Thông báo cho server Socket
    _chatRepository.joinRoom(roomId);

    // Tải lịch sử từ Firestore
    loadMessagesFromFirestore(roomId);

    //_isLoading = false;
    notifyListeners();
  }

  // --- 3. GỬI TIN NHẮN (OPTIMISTIC UI) ---
  void SendMessage(String id, String content, String roomId, String userId) {
    if (content.trim().isEmpty) return;

    final newMsg = ChatMessageModel(
      id: id,
      content: content,
      roomId: roomId,
      senderId: userId,
      sentAt: DateTime.now(),
    );

    // 1. Gửi qua socket
    _chatRepository.sendMessage(newMsg);

    // 2. Thêm ngay vào UI để tạo cảm giác mượt mà (Optimistic Update)
    _internalAddMessage(newMsg);
  }

  // --- 4. TẢI DỮ LIỆU TỪ FIRESTORE ---
  Future<void> loadMessagesFromFirestore(String roomId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chat_messages')
          .where('roomId', isEqualTo: roomId)
          .orderBy('sentAt', descending: true)
          .limit(
            50,
          ) // Senior tip: Luôn có limit để tối ưu hóa chi phí/hiệu suất
          .get();

      final List<ChatMessageModel> historyMessages = snapshot.docs.map((doc) {
        return ChatMessageModel.fromJson({...doc.data(), 'id': doc.id});
      }).toList();

      // Gộp dữ liệu cũ vào danh sách hiện tại và loại bỏ trùng lặp
      for (var msg in historyMessages) {
        _internalAddMessage(msg);
      }
    } catch (e) {
      debugPrint('Senior Log - Firestore Error: $e');
    }
  }

  // --- 5. HÀM TIỆN ÍCH NỘI BỘ (HELPER) ---
  void _internalAddMessage(ChatMessageModel msg) {
    // CHỐT CHẶN CUỐI: Chống trùng lặp tin nhắn dựa trên ID
    final bool isDuplicate = _messages.any((existing) => existing.id == msg.id);

    if (!isDuplicate) {
      // Tìm vị trí đúng để chèn tin nhắn dựa trên thời gian (nếu cần)
      // Ở đây ta đơn giản là thêm vào đầu vì ListView dùng reverse: true
      _messages.insert(0, msg);

      // Sắp xếp lại nhẹ để đảm bảo tin nhắn cũ load từ Firestore không bị nhảy lung tung
      _messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      notifyListeners();
    }
  }

  // Xóa cache khi logout hoặc không dùng nữa
  void clearState() {
    _messages.clear();
    _activeRoomId = null;
    notifyListeners();
  }
}
