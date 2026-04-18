class NotificationModel {
  final String id;
  final String title;
  final String body;
   final String type;
  final String? orderId; // Thêm cái này để "gắn link" tới đơn hàng
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.orderId, // Có thể null nếu là thông báo khuyến mãi chung
    required this.isRead,
    required this.createdAt,
  });
}