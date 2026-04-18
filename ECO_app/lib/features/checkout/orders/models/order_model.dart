
enum OrderStatus { confirming, shipping, delivered, cancelled }
enum PaymentStatus { unpaid, paid }

class OrderModel {
  final String id;
  final String customerName;
  final String address;
  final double totalAmount;
  OrderStatus status;
  PaymentStatus paymentStatus;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.address,
    required this.totalAmount,
    this.status = OrderStatus.confirming,
    required this.paymentStatus,
  });
}
