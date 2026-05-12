import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart'; // Import để lấy token
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../../../core/constants/app_routes.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isFirstLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Chỉ chạy lần đầu tiên khi mở màn hình
    if (_isFirstLoad) {
      _loadOrderData();
      _isFirstLoad = false;
    }
  }

  Future<void> _loadOrderData() async {
    // 1. Lấy orderId từ arguments mà checkout_screen truyền sang
    final orderId = ModalRoute.of(context)!.settings.arguments as String?;

    if (orderId != null) {
      final authProvider = context.read<AuthProvider>();
      final orderProvider = context.read<OrderProvider>();

      // 2. Lấy token thật từ Firebase thông qua AuthProvider
      final token = await authProvider.getUserToken();

      if (token != null) {
        // 3. Bảo Provider đi "lôi" dữ liệu đơn hàng này về
        await orderProvider.fetchOrderById(orderId, token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: orderProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Hiện vòng quay khi đang lấy data
          : order == null
          ? const Center(child: Text("Không tìm thấy thông tin đơn hàng"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderPipeline(order.status),
                  const Divider(height: 40),

                  _buildInfoTile("Mã đơn hàng", order.orderCode),
                  _buildInfoTile("Địa chỉ giao", order.address),

                  _buildInfoTile(
                    "Tạm tính",
                    "${order.totalAmount.toStringAsFixed(0)}đ",
                  ),
                  if (order.discount > 0)
                    _buildInfoTile(
                      "Giảm giá",
                      "-${order.discount.toStringAsFixed(0)}đ",
                      color: Colors.green,
                    ),

                  const Divider(),
                  _buildInfoTile(
                    "Tổng thanh toán",
                    "${order.finalAmount.toStringAsFixed(0)}đ",
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 30),

                  if (order.status == OrderStatus.pending ||
                      order.status == OrderStatus.confirming)
                    // Tại nút Hủy đơn hàng trong OrderDetailsScreen
                    _buildActionButton(
                      context,
                      "Hủy đơn hàng",
                      Colors.red,
                      () async {
                        final authProvider = context.read<AuthProvider>();
                        final orderProvider = context.read<OrderProvider>();

                        // 1. Lấy token thật
                        final token = await authProvider.getUserToken();

                        if (token != null) {
                          // 2. Truyền token vào hàm hủy
                          await orderProvider.cancelOrder(token);

                          // 🚩 QUAN TRỌNG: Kiểm tra mounted trước khi dùng context sau await
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Đơn hàng đã được hủy"),
                            ),
                          );
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.home,
                            (route) => false,
                          );
                        }
                      },
                    ),

                  if (order.status == OrderStatus.cancelled)
                    const Center(
                      child: Text(
                        "Đơn hàng này đã bị hủy",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderPipeline(OrderStatus status) {
    int currentStep = 0;
    if (status == OrderStatus.confirming) currentStep = 1;
    if (status == OrderStatus.shipping) currentStep = 2;
    if (status == OrderStatus.delivered) currentStep = 3;
    if (status == OrderStatus.cancelled) currentStep = -1;

    return Stepper(
      physics: const NeverScrollableScrollPhysics(),
      currentStep: currentStep == -1 ? 0 : currentStep,
      controlsBuilder: (context, details) => const SizedBox.shrink(),
      steps: [
        Step(
          title: const Text("Chờ xác nhận"), // Thêm bước chờ
          content: const SizedBox.shrink(),
          isActive: currentStep >= 0,
          state: status == OrderStatus.cancelled
              ? StepState.error
              : (currentStep >= 0 ? StepState.complete : StepState.indexed),
        ),
        Step(
          title: const Text("Đã xác nhận"),
          content: const SizedBox.shrink(),
          isActive: currentStep >= 1,
          state: currentStep >= 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: const Text("Đang giao"),
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
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
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
