import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import '../models/cart_item_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('cart screen Quản lý giỏ hàng'),
          bottom: const TabBar(
            indicatorColor: Colors.green,
            tabs: [
              Tab(icon: Icon(Icons.storefront), text: 'Chợ Đồ Cũ'),
              Tab(icon: Icon(Icons.recycling), text: 'Gom Rác Đổi Quà'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CartListSection(type: CartItemType.market),
            _CartListSection(type: CartItemType.recycle),
          ],
        ),
        bottomNavigationBar: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                // Truyền index trực tiếp vào Footer mỗi khi Tab thay đổi
                return _CartSummaryFooter(tabIndex: tabController.index);
              },
            );
          },
        ),
      ),
    );
  }
}

class _CartListSection extends StatelessWidget {
  final CartItemType type;
  const _CartListSection({required this.type});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = type == CartItemType.market ? cart.marketItems : cart.recycleItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Chưa có mục nào trong danh sách', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(type == CartItemType.market ? Formatters.money(item.product.price) : 'Quy đổi voucher'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: () => cart.updateQuantity(item.product.id, item.type, -1), icon: const Icon(Icons.remove_circle_outline)),
                Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => cart.updateQuantity(item.product.id, item.type, 1), icon: const Icon(Icons.add_circle_outline, color: Colors.green)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartSummaryFooter extends StatelessWidget {
  final int tabIndex; // Thêm biến để nhận giá trị index

  // Yêu cầu truyền tabIndex khi gọi Widget này
  const _CartSummaryFooter({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    // Khai báo biến màu sắc dựa trên tabIndex cho gọn gàng
    final primaryColor = tabIndex == 0 ? Colors.green : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tabIndex == 0 ? 'Phí ship: 30.000 \nTổng thanh toán:' : 'Điểm tích lũy dự kiến:'),
                Text(
                  tabIndex == 0 ? Formatters.money(cart.totalMarketPrice) : '${cart.totalRecyclePoints} pts',
                  // Bỏ const ở TextStyle và sử dụng biến primaryColor
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // Sử dụng biến primaryColor cho màu nền nút
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.checkout),
                child: Text(tabIndex == 0 ? 'MUA HÀNG NGAY' : 'ĐẶT LỊCH THU GOM'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}