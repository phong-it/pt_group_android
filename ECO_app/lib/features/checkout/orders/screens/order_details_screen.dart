import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../notifications/providers/notification_provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../../../../core/constants/app_routes.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;

    if (order == null) return const Scaffold(body: Center(child: Text("Không có đơn hàng")));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tiến trình đơn hàng (Pipeline)
            _buildOrderPipeline(order.status),
            const Divider(height: 40),

            // 2. Thông tin thanh toán & Khách hàng
            _buildInfoTile("Mã đơn hàng", order.id),
            _buildInfoTile("Khách hàng", order.customerName),
            _buildInfoTile("Trạng thái thanh toán",
                order.paymentStatus == PaymentStatus.paid ? "Đã thanh toán" : "Chưa thanh toán",
                color: order.paymentStatus == PaymentStatus.paid ? Colors.green : Colors.red),
            _buildInfoTile("Tổng tiền", "${order.totalAmount.toStringAsFixed(0)}đ"),

            const SizedBox(height: 30),

            // 3. Logic các nút bấm
            // 3. Logic các nút bấm
            if (order.status == OrderStatus.confirming)
              _buildActionButton(context, "Hủy đơn hàng", Colors.red, () {
                // 1. Lấy NotificationProvider
                final notifProvider = context.read<NotificationProvider>();

                // 2. Gọi provider để xử lý logic (đã truyền thêm notifProvider)
                context.read<OrderProvider>().cancelOrder(notifProvider);

                // 3. Thông báo cho người dùng
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đơn hàng đã được hủy thành công")),
                );

                // 4. Quay về màn hình chính
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
              }),

            if (order.status == OrderStatus.delivered)
              _buildActionButton(context, "Xác nhận đã nhận hàng", Colors.green, () {
                // Thông báo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cảm ơn bạn đã mua hàng!")),
                );

                // Quay về màn hình chính
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
              }),

            if (order.status == OrderStatus.cancelled)
              const Center(child: Text("Đơn hàng này đã bị hủy", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị tiến trình 3 bước
  Widget _buildOrderPipeline(OrderStatus status) {
    int currentStep = 0;
    if (status == OrderStatus.shipping) currentStep = 1;
    if (status == OrderStatus.delivered) currentStep = 2;
    if (status == OrderStatus.cancelled) currentStep = -1;

    return Stepper(
      physics: const NeverScrollableScrollPhysics(),
      currentStep: currentStep == -1 ? 0 : currentStep,
      controlsBuilder: (context, details) => const SizedBox.shrink(), // Ẩn nút mặc định
      steps: [
        Step(
          title: const Text("Đang xác nhận"),
          content: const SizedBox.shrink(),
          isActive: currentStep >= 0,
          state: status == OrderStatus.cancelled ? StepState.error : (currentStep >= 0 ? StepState.complete : StepState.indexed),
        ),
        Step(
          title: const Text("Đang giao"),
          content: const SizedBox.shrink(),
          isActive: currentStep >= 1,
          state: currentStep >= 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text("Đã giao"),
          content: const SizedBox.shrink(),
          isActive: currentStep >= 2,
          state: currentStep >= 2 ? StepState.complete : StepState.indexed,
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}