import 'package:flutter/material.dart';
import '../../products/models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  final CartService _cartService = CartService();

  // Lấy danh sách theo loại để UI hiển thị dễ dàng
  List<CartItemModel> get marketItems =>
      _items.where((e) => e.type == CartItemType.market).toList();
  List<CartItemModel> get recycleItems =>
      _items.where((e) => e.type == CartItemType.recycle).toList();

  void addProduct(ProductModel product, CartItemType type) {
    final index = _items.indexWhere(
      (e) => e.product.id == product.id && e.type == type,
    );

    CartItemModel itemToSync; // Biến tạm để đồng bộ

    if (index >= 0) {
      _items[index] = CartItemModel(
        product: _items[index].product,
        quantity: _items[index].quantity + 1,
        type: type,
      );
      itemToSync = _items[index];
    } else {
      itemToSync = CartItemModel(product: product, quantity: 1, type: type);
      _items.add(itemToSync);
    }

    notifyListeners();

    // ĐỒNG BỘ LÊN SERVER NGAY LẬP TỨC (Không cần await để tránh đứng máy UI)
    _cartService.syncItemToServer(itemToSync);
  }

  // Cập nhật hàm này trong CartProvider
  void updateQuantity(String productId, CartItemType type, int delta) {
    final index = _items.indexWhere(
      (e) => e.product.id == productId && e.type == type,
    );

    if (index >= 0) {
      final newQty = _items[index].quantity + delta;
      CartItemModel itemToSync;

      if (newQty <= 0) {
        // Tạo item tạm với quantity = 0 để báo Server xóa
        itemToSync = CartItemModel(
          product: _items[index].product,
          quantity: 0,
          type: type,
        );
        _items.removeAt(index);
      } else {
        _items[index] = CartItemModel(
          product: _items[index].product,
          quantity: newQty,
          type: type,
        );
        itemToSync = _items[index];
      }

      notifyListeners();

      // ĐỒNG BỘ LÊN SERVER
      _cartService.syncItemToServer(itemToSync);
    }
  }

  // Logic tính toán cho Chợ đồ cũ
  double get marketSubtotal => marketItems.fold(
    0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );
  double get shippingFee => marketItems.isEmpty ? 0 : 30000;
  double get totalMarketPrice => marketSubtotal + shippingFee;

  // Logic tính toán cho Gom rác (Ví dụ: 1kg rác = 1000 điểm)
  double get totalRecyclePoints =>
      recycleItems.fold(0, (sum, item) => sum + (item.quantity * 1000));

  void clearMarketOnly() {
    _items.removeWhere((e) => e.type == CartItemType.market);
    notifyListeners();
  }
}
