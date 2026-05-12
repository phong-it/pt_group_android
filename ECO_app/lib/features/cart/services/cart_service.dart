import '../../../core/network/api_client.dart';
import '../../products/models/product_model.dart';
import '../models/cart_item_model.dart';

class CartService {
  final ApiClient _apiClient = ApiClient();

  // Hàm gửi thông tin sản phẩm lên Node.js
  Future<void> syncItemToServer(CartItemModel item) async {
    try {
      await _apiClient.post(
        '/cart/sync', // Đường dẫn API vừa tạo ở Node.js
        body: {
          'productId': item.product.id,
          'name': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
          'type': item.type
              .toString()
              .split('.')
              .last, // Gửi chữ 'market' hoặc 'recycle'
        },
      );
      print("Đã đồng bộ sản phẩm ${item.product.name} lên server");
    } catch (e) {
      print("Lỗi đồng bộ giỏ hàng: $e");
    }
  }
}
