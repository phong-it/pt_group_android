import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../screens/add_edit_product_screen.dart';

import '../../cart/providers/cart_provider.dart';
import '../../cart/models/cart_item_model.dart';
import '../../chat/screens/chat_screen.dart';
import '../providers/product_provider.dart';

class ProductBottomBar extends StatelessWidget {
  final ProductModel product;
  const ProductBottomBar({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == product.sellerId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: isOwner 
            ? _buildOwnerActions(context) 
            : _buildBuyerActions(context, currentUserId),
      ),
    );
  }

  // UI DÀNH CHO CHỦ SẢN PHẨM
  Widget _buildOwnerActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
            icon: const Icon(Icons.edit),
            label: const Text('Sửa tin'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductScreen(existingProduct: product)));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text('Xóa tin', style: TextStyle(color: Colors.white)),
            onPressed: () => _handleDelete(context),
          ),
        ),
      ],
    );
  }

  // UI DÀNH CHO KHÁCH HÀNG
  Widget _buildBuyerActions(BuildContext context, String? currentUserId) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.green, side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              if (currentUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để chat!'), backgroundColor: Colors.red));
                return;
              }
              final roomId = _getRoomId(currentUserId, product.sellerId);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => ChatScreen(roomId: roomId, receiverName: "Người bán"),
              ));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: const Text('Thêm vào giỏ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: () {
              final cart = Provider.of<CartProvider>(context, listen: false);
              cart.addProduct(product, CartItemType.market); // Gọi hàm giỏ hàng của bạn
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng!'), backgroundColor: Colors.green));
            },
          ),
        ),
      ],
    );
  }

  // LOGIC XÓA SẢN PHẨM (Dùng Provider)
  Future<void> _handleDelete(BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tin đăng?'),
        content: const Text('Bạn có chắc chắn muốn xóa món đồ này không? Không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      final error = await context.read<ProductProvider>().deleteProduct(product.id);
      
      if (!context.mounted) return;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thành công!'), backgroundColor: Colors.green));
        Navigator.pop(context); // Thoát về trang chủ
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }

  // Thuật toán gộp chung về file này
  String _getRoomId(String userId1, String userId2) {
    List<String> users = [userId1, userId2];
    users.sort();
    return users.join('_');
  }
}