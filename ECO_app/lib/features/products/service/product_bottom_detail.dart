import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Giữ lại Firebase Auth
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../screens/add_edit_product_screen.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/models/cart_item_model.dart';
import '../../chat/screens/chat_screen.dart';

class ProductBottomBar extends StatelessWidget {
  final ProductModel product;
  const ProductBottomBar({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Lấy UID từ Firebase Auth để định danh người dùng
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == product.sellerId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: isOwner
            ? _buildOwnerActions(context)
            : _buildBuyerActions(context, currentUserId),
      ),
    );
  }

  Widget _buildBuyerActions(BuildContext context, String? currentUserId) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text(
              'Chat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              if (currentUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng đăng nhập để chat!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Tạo Room ID từ Firebase UIDs
              final roomId = _generateRoomId(
                currentUserId,
                product.sellerId,
                product.id,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    roomId: roomId,
                    receiverName:
                        "Người bán", // Có thể thay bằng product.sellerName nếu có
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: const Text(
              'Thêm vào giỏ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              final cart = Provider.of<CartProvider>(context, listen: false);
              cart.addProduct(product, CartItemType.market);
            },
          ),
        ),
      ],
    );
  }

  // Thuật toán tạo Room ID duy nhất cho 2 người
  String _generateRoomId(String id1, String id2, String productId) {
    List<String> ids = [id1, id2];
    ids.sort(); // Đảm bảo tính nhất quán
    return "${ids.join('_')}_$productId"; // Thêm productId vào cuối
  }

  // ... Giữ lại các hàm _buildOwnerActions và _handleDelete của bạn ...
  Widget _buildOwnerActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Sửa tin'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddProductScreen(existingProduct: product),
              ),
            ),
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

  Future<void> _handleDelete(BuildContext context) async {
    // Logic hiển thị dialog xóa cũ của bạn
  }
}
