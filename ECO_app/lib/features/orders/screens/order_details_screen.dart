import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import 'package:frontend/features/chat/services/socket_service.dart';
import '../../../core/constants/app_routes.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late String _orderId;
  bool _isInitialized = false;
  StreamSubscription<Map<String, dynamic>>? _orderStatusSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is String) {
        _orderId = args;
        _initSocketListener();
        _loadOrderData();
      }
      _isInitialized = true;
    }
  }

  void _initSocketListener() {
    final socketService = context.read<SocketService>();
    _orderStatusSubscription?.cancel();

    // LẮNG NGHE ĐỒNG BỘ: Khi có biến động số dư thành công, kéo lại toàn bộ data mới từ Firestore
    _orderStatusSubscription = socketService.onOrderStatusChanged.listen((
      data,
    ) {
      final String incomingOrderId = data['orderId'].toString();
      if (incomingOrderId == _orderId) {
        _loadOrderData(); // Kéo lại dữ liệu để cập nhật trường paymentStatus mới nhất
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "⚡ Cập nhật: Hệ thống đã ghi nhận trạng thái đơn hàng thay đổi!",
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _orderStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    final authProvider = context.read<AuthProvider>();
    final token = await authProvider.getUserToken();
    if (token != null && mounted) {
      await context.read<OrderProvider>().fetchOrderById(_orderId, token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: _buildAppBar(),
      body: _buildBody(orderProvider, order),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Chi tiết đơn hàng',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  Widget _buildBody(OrderProvider provider, OrderModel? order) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (order == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrderData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // CHỈ HIỂN THỊ QR NẾU ĐƠN CHƯA ĐƯỢC THANH TOÁN (UNPAID)
            if (order.paymentMethod == 'QR_TRANSFER' &&
                order.paymentStatus == 'unpaid' &&
                order.qrData != null)
              _buildCleanPaymentQRCard(context, order),

            const SizedBox(height: 12),
            _buildStatusHeader(order.status, order.paymentStatus),
            const SizedBox(height: 16),
            _buildTimelineCard(order.status),
            const SizedBox(height: 16),
            _buildInfoSection(
              title: "Thông tin đơn hàng",
              icon: Icons.assignment_outlined,
              content: [
                _buildDataRow("Mã đơn", order.orderCode, isBold: true),
                _buildDataRow("Địa chỉ", order.address),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaymentSummary(order),
            const SizedBox(height: 24),
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanPaymentQRCard(BuildContext context, OrderModel order) {
    final qrInfo = order.qrData!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Quét mã chuyển khoản",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Số tiền sẽ tự động nhập vào ứng dụng ngân hàng khi quét",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: qrInfo.qrCode,
              version: QrVersions.auto,
              size: 180.0,
              gapless: false,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SỐ TÀI KHOẢN",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      qrInfo.accountNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: qrInfo.accountNumber),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép số tài khoản thành công!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Sao chép",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(OrderStatus status, String paymentStatus) {
    final isPaid = paymentStatus == 'paid';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getStatusColor(status),
            child: const Icon(Icons.inventory_2, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Vận chuyển: ${_getStatusLabel(status)}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPaid
                      ? "Thanh toán: ĐÃ THANH TOÁN HOÀN TẤT"
                      : "Thanh toán: CHƯA THANH TOÁN",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(OrderStatus status) {
    final steps = ["Chờ", "Xác nhận", "Giao", "Đã nhận"];
    int currentStep = 0;

    switch (status) {
      case OrderStatus.pending:
        currentStep = 0;
        break;
      case OrderStatus.confirmed:
        currentStep = 1;
        break;
      case OrderStatus.picked_up:
      case OrderStatus.shipping:
        currentStep = 2;
        break;
      case OrderStatus.delivered:
        currentStep = 3;
        break;
      case OrderStatus.cancelled:
        currentStep = -1;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isDone = index <= currentStep && currentStep != -1;
            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: index == 0
                              ? Colors.transparent
                              : (isDone ? Colors.green : Colors.grey[300]),
                        ),
                      ),
                      Icon(
                        isDone ? Icons.check_circle : Icons.radio_button_off,
                        size: 20,
                        color: isDone ? Colors.green : Colors.grey[400],
                      ),
                      Expanded(
                        child: Divider(
                          color: index == steps.length - 1
                              ? Colors.transparent
                              : (index < currentStep
                                    ? Colors.green
                                    : Colors.grey[300]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: isDone ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          ...content,
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(OrderModel order) {
    final bool isPaid = order.paymentStatus == 'paid';
    return _buildInfoSection(
      title: "Tổng cộng thanh toán",
      icon: Icons.payments_outlined,
      content: [
        _buildDataRow(
          "Tổng tiền hàng",
          "${order.finalAmount.toStringAsFixed(0)}đ",
        ),
        _buildDataRow("Phí vận chuyển", "Miễn phí", color: Colors.green),
        if (isPaid)
          _buildDataRow(
            "Đã thanh toán qua QR",
            "-${order.finalAmount.toStringAsFixed(0)}đ",
            color: Colors.green,
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(),
        ),
        _buildDataRow(
          "Tổng thanh toán hiện tại",
          isPaid ? "0đ" : "${order.finalAmount.toStringAsFixed(0)}đ",
          isBold: true,
          fontSize: 18,
          color: isPaid ? Colors.green.shade700 : Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    if (order.status == OrderStatus.pending) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          elevation: 0,
          side: const BorderSide(color: Colors.red),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _confirmCancel(),
        child: const Text(
          "HỦY ĐƠN HÀNG",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Xác nhận hủy"),
        content: const Text(
          "Bạn có chắc chắn muốn hủy đơn hàng này? Thao tác này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Quay lại"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processCancel();
            },
            child: const Text(
              "Đồng ý hủy",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processCancel() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final token = await authProvider.getUserToken();

    if (token != null) {
      await orderProvider.cancelOrder(token);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("Không tìm thấy thông tin đơn hàng"),
          TextButton(onPressed: _loadOrderData, child: const Text("Thử lại")),
        ],
      ),
    );
  }

  String _getStatusLabel(dynamic status) {
    if (status is OrderStatus) {
      switch (status) {
        case OrderStatus.pending:
          return "Chờ xử lý";
        case OrderStatus.confirmed:
          return "Đã xác nhận";
        case OrderStatus.picked_up:
          return "Shipper đã lấy hàng";
        case OrderStatus.shipping:
          return "Đang giao hàng";
        case OrderStatus.delivered:
          return "Đã giao thành công";
        case OrderStatus.cancelled:
          return "Đã hủy";
      }
    }
    return status.toString();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.shipping:
        return Colors.blue;
      case OrderStatus.pending:
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}
