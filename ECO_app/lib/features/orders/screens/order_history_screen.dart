import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/order_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order_model.dart';
import 'order_details_screen.dart';
import '../../profile/screens/profile_menu.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Sử dụng microtask hoặc postFrameCallback để tránh lỗi conflict provider khi build
    Future.microtask(() async {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final String? token = await authProvider.getUserToken();

      if (mounted && token != null) {
        await context.read<OrderProvider>().fetchOrders(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Lịch sử đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          // 1. Loading State
          if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          // 2. Error State
          if (orderProvider.errorMessage != null &&
              orderProvider.orders.isEmpty) {
            return _buildErrorState(orderProvider.errorMessage!);
          }

          // 3. Empty State
          if (orderProvider.orders.isEmpty) {
            return _buildEmptyState();
          }

          // 4. Main Content
          return RefreshIndicator(
            onRefresh: _loadData,
            color: Theme.of(context).primaryColor,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orderProvider.orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                return _OrderCard(
                  order: order,
                  currencyFormat: _currencyFormat,
                  dateFormat: _dateFormat,
                  onTap: () => _navigateToDetail(context, order, orderProvider),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(
    BuildContext context,
    OrderModel order,
    OrderProvider provider,
  ) {
    provider.setCurrentOrderById(order.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const OrderDetailsScreen(), // Không truyền trực tiếp vào đây
        settings: RouteSettings(
          arguments: order.id,
        ), // Truyền qua arguments ở đây
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Chưa có đơn hàng nào",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tiếp tục mua sắm"),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
            ),
          ],
        ),
      ),
    );
  }
}

// Tách Card ra thành 1 Stateless Widget riêng để tối ưu hóa việc rebuild
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.currencyFormat,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order.orderCode}', // Dùng orderCode thay vì id substring cho chuyên nghiệp
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.address, // Hiển thị địa chỉ vì không có createdAt
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chi tiết đơn hàng', // Thay vì order.items.length (vì model không có)
                      style: TextStyle(color: Colors.black87),
                    ),
                    Text(
                      currencyFormat.format(
                        order.finalAmount,
                      ), // Sửa totalAmount -> finalAmount
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sửa lỗi Enum mapping (Dòng 260 - 264)
  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        label = "Chờ xử lý";
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        label = "Đã xác nhận";
        break;
      case OrderStatus.picked_up:
        color = Colors.purple;
        label = "Shipper đã lấy hàng";
        break;
      case OrderStatus.shipping: // Thay cho 'delivering'
        color = Colors.blue;
        label = "Đang giao";
        break;
      case OrderStatus.delivered: // Thay cho 'completed'
        color = Colors.green;
        label = "Đã giao";
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        label = "Đã hủy";
        break;
      default:
        color = Colors.grey;
        label = "Không xác định";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
