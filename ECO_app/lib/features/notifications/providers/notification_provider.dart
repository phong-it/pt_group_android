import 'package:flutter/material.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../../chat/services/socket_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _items = [];
  List<NotificationModel> get items => List.unmodifiable(_items);
  StreamSubscription? _notificationSubscription;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void addNotification({
    required String title,
    required String body,
    String? roomId,
    String? orderId,
    required String type,
  }) {
    _items.insert(
      0,
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        orderId: orderId,
        type: type,
        roomId: roomId,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _items[index] = NotificationModel(
        id: _items[index].id,
        title: _items[index].title,
        body: _items[index].body,
        type: _items[index].type,
        isRead: true,
        createdAt: _items[index].createdAt,
      );
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool hasChanges = false;

    for (int i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) {
        // Đúc lại khuôn mới giống hệt cái cũ, chỉ đổi isRead thành true
        _items[i] = NotificationModel(
          id: _items[i].id,
          title: _items[i].title,
          body: _items[i].body,
          type: _items[i].type,
          orderId: _items[i].orderId,
          isRead: true, // <-- Đổi thành true
          createdAt: _items[i].createdAt,
        );
        hasChanges = true;
      }
    }
    // Chỉ báo UI vẽ lại nếu thực sự có thông báo vừa được chuyển trạng thái
    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Kết nối Provider với luồng Stream của Socket
  void setupSocketListener(SocketService socketService) {
    // Hủy đăng ký cũ nếu có để tránh bị duplicate event
    _notificationSubscription?.cancel();

    _notificationSubscription = socketService.onNotification.listen((data) {
      // Bóc tách JSON từ luồng
      final String orderId = data['orderId'] ?? '';
      final String message = data['message'] ?? 'Đơn hàng của bạn vừa cập nhật trạng thái';
      final String status = data['status'] ?? '';

      // Đẩy vào danh sách & báo UI cập nhật
      addNotification(
        title: status == 'delivered' ? 'Giao hàng thành công' : 'Cập nhật đơn hàng',
        body: message,
        orderId: orderId,
        type: 'order_$status', 
      );
    });
  }

  Future<void> fetchNotifications(String userId) async {
    if (userId.isEmpty) return;

    _isLoading = true;
    notifyListeners(); // Bật trạng thái loading để UI biết

    try {
      print(">>> Đang tải lịch sử thông báo cho user: $userId");
      
      // 1. Truy vấn Firebase: Lọc theo userId và sắp xếp thời gian giảm dần
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true) 
          .get();

      // 2. Bóc tách dữ liệu và chuyển thành List<NotificationModel>
      _items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        // Xử lý an toàn kiểu dữ liệu thời gian 
        // (Đôi khi Firebase lưu là Timestamp, đôi khi lưu là String ISO)
        DateTime parsedDate = DateTime.now();
        if (data['createdAt'] is Timestamp) {
          parsedDate = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          parsedDate = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
        }

        return NotificationModel(
          id: doc.id, // Dùng chính ID của document trên Firebase để sau này dễ update trạng thái Đã đọc
          title: data['title'] ?? 'Thông báo',
          body: data['body'] ?? '',
          type: data['type'] ?? 'system',
          orderId: data['orderId'],
          isRead: data['isRead'] ?? false,
          createdAt: parsedDate,
        );
      }).toList();

    } catch (e) {
      print("❌ Lỗi khi tải lịch sử thông báo: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Tắt trạng thái loading, báo UI vẽ lại danh sách
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
