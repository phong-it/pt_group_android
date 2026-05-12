import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../../core/network/api_client.dart';
// Giả sử bạn dùng intl để format tiền và ngày tháng
// import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi dữ liệu ngay khi vào trang
    _loadData();
  }

  Future<void> _loadData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final String? token = await authProvider.getUserToken();

      if (mounted && token != null) {
        context.read<OrderProvider>().fetchOrders(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử đơn hàng'), elevation: 0),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          // 1. Xử lý trạng thái Loading
          if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Xử lý trạng thái Lỗi
          if (orderProvider.errorMessage != null &&
              orderProvider.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    orderProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          }

          // 3. Xử lý trạng thái Rỗng
          if (orderProvider.orders.isEmpty) {
            return const Center(child: Text("Bạn chưa có đơn hàng nào."));
          }

          // 4. Danh sách chính với RefreshIndicator
          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: orderProvider.orders.length,
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                return _buildOrderCard(context, order, orderProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, order, orderProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          // Fix: Gọi đúng tên hàm đã thêm vào Provider
          orderProvider.setCurrentOrderById(order.id);
          Navigator.pushNamed(context, AppRoutes.orderDetail);
        },
        title: Text(
          "Đơn hàng #${order.orderCode}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Tổng: ${order.finalAmount}đ",
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
