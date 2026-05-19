// order_model.dart
enum OrderStatus {
  pending, // Chờ xử lý
  confirmed, // Đã xác nhận (Backend gọi là confirmed)
  picked_up, // Shipper đã lấy hàng (Bổ sung cho khớp Backend)
  shipping, // Đang giao
  delivered, // Đã giao
  cancelled, // Đã hủy
}

class QrDataModel {
  final String qrCode;
  final String checkoutUrl;
  final String accountNumber;
  final String accountName;

  QrDataModel({
    required this.qrCode,
    required this.checkoutUrl,
    required this.accountNumber,
    required this.accountName,
  });

  factory QrDataModel.fromJson(Map<String, dynamic> json) {
    return QrDataModel(
      qrCode: json['qrCode'] ?? '',
      checkoutUrl: json['checkoutUrl'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
    );
  }
}

class OrderModel {
  final String id;
  final String orderCode;
  final String address;
  final double finalAmount;
  final String paymentMethod;
  final QrDataModel? qrData;
  final String paymentStatus; // ĐÃ THÊM: Quản lý ví điện tử ngầm
  OrderStatus status;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.address,
    required this.finalAmount,
    required this.paymentMethod,
    this.qrData,
    required this.paymentStatus, // ĐÃ THÊM
    required this.status,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    return OrderModel(
      id: docId ?? json['id'] ?? '',
      orderCode: json['orderCode'] ?? 'ECO-000000',
      address: json['shippingAddress'] ?? json['address'] ?? '',
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'COD',
      qrData: json['qrData'] != null ? QrDataModel.fromJson(json['qrData']) : null,
      paymentStatus: json['paymentStatus'] ?? 'unpaid', // ĐỌC GIÁ TRỊ SẠCH TỪ SERVER
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
    );
  }
}