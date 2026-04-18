import 'package:flutter/material.dart';
import '../models/notification_model.dart';


class NotificationProvider extends ChangeNotifier {
  final List<NotificationModel> _items = [];
  List<NotificationModel> get items => List.unmodifiable(_items);

  void addNotification({required String title, required String body, String? orderId, required String type}) {
    _items.insert(
      0,
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        orderId: orderId,
        type: type,
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
}