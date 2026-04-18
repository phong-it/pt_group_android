import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../../../notifications/providers/notification_provider.dart';
class OrderProvider extends ChangeNotifier {
  OrderModel? _currentOrder;
  OrderModel? get currentOrder => _currentOrder;

  // Chúng ta sẽ truyền NotificationProvider vào hàm này
  Future<void> simulateOrderProcess(NotificationProvider notificationProvider) async {
    if (_currentOrder == null) return;

    // 1. Đặt hàng thành công
    _addLog(notificationProvider, "Đặt hàng thành công", "Đơn hàng ${_currentOrder!.id} đã được khởi tạo.");

    await Future.delayed(const Duration(seconds: 3));
    _currentOrder!.status = OrderStatus.confirming;
    _addLog(notificationProvider, "Đang xác nhận", "Shop đang kiểm tra đơn hàng của bạn.");
    notifyListeners();

    await Future.delayed(const Duration(seconds: 5));
    _currentOrder!.status = OrderStatus.shipping;
    _addLog(notificationProvider, "Đang giao hàng", "Shipper đang mang hàng đến chỗ bạn.");
    notifyListeners();

    await Future.delayed(const Duration(seconds: 5));
    _currentOrder!.status = OrderStatus.delivered;
    _addLog(notificationProvider, "Giao hàng hoàn tất", "Cảm ơn bạn đã mua sắm tại Eco Market!");
    notifyListeners();
  }

  // Hàm hỗ trợ viết code ngắn gọn hơn
  void _addLog(NotificationProvider provider, String title, String body) {
    provider.addNotification(
      title: title,
      body: body,
      type: 'order',
      orderId: _currentOrder?.id,
    );
  }
  void createOrder(OrderModel order, NotificationProvider notifProvider) {
    _currentOrder = order;
    notifyListeners();

    // 1. Gửi thông báo ngay khi tạo đơn
    _addLog(notifProvider, "Đặt hàng thành công", "Đơn hàng ${order.id} đã được khởi tạo và đang chờ xử lý.");

    // 2. Chạy hàm mô phỏng (Nhớ truyền notifProvider vào hàm simulateOrderProcess)
    simulateOrderProcess(notifProvider);
  }

  void updateStatus(OrderStatus newStatus, NotificationProvider notifProvider) {
    if (_currentOrder != null && _currentOrder!.status != newStatus) {
      _currentOrder!.status = newStatus;
      notifyListeners();

      // Dựa vào trạng thái mới để gửi thông báo phù hợp
      String title = "";
      String body = "";

      switch (newStatus) {
        case OrderStatus.confirming:
          title = "Đơn hàng đang xác nhận";
          body = "Shop đang chuẩn bị đơn hàng ${_currentOrder!.id} cho bạn.";
          break;
        case OrderStatus.shipping:
          title = "Đơn hàng đang giao";
          body = "Shipper đã lấy hàng và đang trên đường đến giao cho bạn.";
          break;
        case OrderStatus.delivered:
          title = "Giao hàng thành công";
          body = "Đơn hàng ${_currentOrder!.id} đã được giao. Cảm ơn bạn!";
          break;
        case OrderStatus.cancelled:
          title = "Đơn hàng đã hủy";
          body = "Đơn hàng ${_currentOrder!.id} đã bị hủy.";
          break;
      }

      _addLog(notifProvider, title, body);
    }
  }

  void cancelOrder(NotificationProvider notifProvider) {
    if (_currentOrder != null && _currentOrder!.status != OrderStatus.cancelled) {
      _currentOrder!.status = OrderStatus.cancelled;
      notifyListeners();

      // Gửi thông báo hủy đơn
      _addLog(notifProvider, "Hủy đơn hàng", "Bạn đã hủy thành công đơn hàng ${_currentOrder!.id}.");
    }
  }
}