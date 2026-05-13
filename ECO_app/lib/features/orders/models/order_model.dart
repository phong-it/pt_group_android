// order_model.dart
enum OrderStatus {
  pending, // Chờ xử lý
  confirmed, // Đã xác nhận (Backend gọi là confirmed)
  picked_up, // Shipper đã lấy hàng (Bổ sung cho khớp Backend)
  shipping, // Đang giao
  delivered, // Đã giao
  cancelled, // Đã hủy
}

class OrderModel {
  final String id; // Document ID của Firebase
  final String orderCode; // Mã ECO-xxxx
  final String address;
  final double finalAmount;
  OrderStatus status;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.address,
    required this.finalAmount,
    required this.status,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return OrderModel(
      id: docId ?? json['id'] ?? '',
      orderCode: json['orderCode'] ?? 'ECO-000000',
      address: json['shippingAddress'] ?? json['address'] ?? '',
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      // Senior Tip: Dùng .name để so sánh chuỗi enum trực tiếp với Backend string
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
    );
  }
}
