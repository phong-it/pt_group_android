enum OrderStatus { pending, confirming, shipping, delivered, cancelled }

enum PaymentStatus { unpaid, paid }

class OrderModel {
  final String id;
  final String orderCode;
  final String address;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  OrderStatus status;
  PaymentStatus paymentStatus;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.address,
    required this.totalAmount,
    required this.discount,
    required this.finalAmount,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.unpaid,
  });

  // --- SENIOR TIP: Dùng Map để parse Status cực nhanh và sạch ---
  static OrderStatus _parseStatus(String? status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OrderStatus.pending,
    );
  }

  static PaymentStatus _parsePayment(String? status) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return OrderModel(
      // Ưu tiên docId truyền vào, nếu không có thì tìm trong json['id'] hoặc json['_id']
      id: docId ?? json['id'] ?? json['_id'] ?? '',
      orderCode: json['orderCode'] ?? 'ECO-000000',
      // Kiểm tra kỹ tên trường: 'shippingAddress' hay 'address'?
      address: json['shippingAddress'] ?? json['address'] ?? 'Chưa cung cấp',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      status: _parseStatus(json['status']),
      paymentStatus: _parsePayment(json['paymentStatus']),
    );
  }
}
