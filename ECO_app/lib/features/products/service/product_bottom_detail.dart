import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Giữ lại Firebase Auth
import 'package:frontend/features/products/service/product_service.dart';
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
    // 1. Hiển thị hộp thoại xác nhận trước khi xóa
    final bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa tin đăng bán này không? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), // Trả về false nếu Hủy
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true), // Trả về true nếu Đồng ý
              child: const Text('Xóa ngay', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    // Nếu người dùng chọn "Hủy" hoặc bấm ra ngoài hộp thoại
    if (confirm != true) return;

    // 2. Gọi hàm xóa từ ProductService (Nhớ import ProductService vào file này nhé)
    // Thêm loading UX (tùy chọn nhưng nên có)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang xóa sản phẩm...')),
    );

    // Gọi API xóa (Lưu ý: Bạn phải truyền product.id vào)
    final error = await ProductService().deleteProduct(product.id);

    // 3. Xử lý kết quả trả về
    if (error == null) {
      // Xóa thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa tin đăng thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      // Xóa xong thì thoát khỏi màn hình chi tiết sản phẩm
      Navigator.pop(context); 
    } else {
      // Xóa thất bại (do lỗi mạng hoặc quyền Firebase)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
