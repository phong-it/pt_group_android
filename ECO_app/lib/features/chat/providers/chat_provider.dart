import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // HÀM 1: Lắng nghe tin nhắn theo thời gian thực (Giữ nguyên, chỉ thêm handle lỗi nhẹ)
  Stream<List<ChatMessageModel>> getMessagesStream(String roomId) {
    return _db
        .collection('chat_messages')
        .where('roomId', isEqualTo: roomId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // HÀM 2: Gửi tin nhắn (ĐÃ NÂNG CẤP)
  // Đổi thành Future<bool> để UI biết gửi thành công (true) hay thất bại (false)
  Future<bool> sendMessage(String roomId, String senderId, String content) async {
    if (content.trim().isEmpty) return false;

    try {
      // Khởi tạo một Batch (Gói thao tác)
      final batch = _db.batch();

      // 1. Chuẩn bị thao tác THÊM TIN NHẮN
      // Tạo trước một Document rỗng để lấy ID
      final messageRef = _db.collection('chat_messages').doc();

      final newMessage = ChatMessageModel(
        id: messageRef.id,
        roomId: roomId,
        senderId: senderId,
        content: content.trim(),
        sentAt: DateTime.now(), // Tạm thời để cho Model không báo lỗi
      );

      // Chuyển thành Map và GHI ĐÈ thời gian bằng giờ Server cho chuẩn xác
      Map<String, dynamic> messageData = newMessage.toMap();
      messageData['sentAt'] = FieldValue.serverTimestamp();

      batch.set(messageRef, messageData); // Thêm vào gói

      // 2. Chuẩn bị thao tác CẬP NHẬT PHÒNG CHAT
      final roomRef = _db.collection('chat_rooms').doc(roomId);
      
      // SỬA DÒNG NÀY: Dùng batch.set kèm SetOptions(merge: true) thay vì batch.update
      batch.set(roomRef, {
        'lastMessage': content.trim(),
        'lastTime': FieldValue.serverTimestamp(),
        // 💡 Tiện tay lưu luôn danh sách 2 người chat để sau này dễ làm màn hình Danh sách phòng chat
        'users': roomId.split('_'), 
      }, SetOptions(merge: true));

      // 3. THỰC THI TOÀN BỘ GÓI CÙNG LÚC
      await batch.commit();

      return true; // Thành công
    } catch (e) {
      print("Lỗi khi gửi tin nhắn: $e");
      return false; // Thất bại
    }
  }
}