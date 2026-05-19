import 'package:flutter/material.dart';
import '../../products/models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  final CartService _cartService = CartService();

  // === SELECTION STATE ===
  // Key = "productId_type" để phân biệt market vs recycle
  final Set<String> _selectedIds = {};

  String _selectionKey(String productId, CartItemType type) =>
      '${productId}_${type.name}';

  bool isSelected(String productId, CartItemType type) =>
      _selectedIds.contains(_selectionKey(productId, type));

  void toggleSelection(String productId, CartItemType type) {
    final key = _selectionKey(productId, type);
    if (_selectedIds.contains(key)) {
      _selectedIds.remove(key);
    } else {
      _selectedIds.add(key);
    }
    notifyListeners();
  }

  void selectAll(CartItemType type) {
    final items = type == CartItemType.market ? marketItems : recycleItems;
    final allSelected = items.every((e) => isSelected(e.product.id, e.type));
    if (allSelected) {
      // Bỏ chọn tất cả
      for (final item in items) {
        _selectedIds.remove(_selectionKey(item.product.id, item.type));
      }
    } else {
      // Chọn tất cả
      for (final item in items) {
        _selectedIds.add(_selectionKey(item.product.id, item.type));
      }
    }
    notifyListeners();
  }

  bool isAllSelected(CartItemType type) {
    final items = type == CartItemType.market ? marketItems : recycleItems;
    if (items.isEmpty) return false;
    return items.every((e) => isSelected(e.product.id, e.type));
  }

  int selectedCount(CartItemType type) {
    final items = type == CartItemType.market ? marketItems : recycleItems;
    return items.where((e) => isSelected(e.product.id, e.type)).length;
  }

  // === DANH SÁCH ===
  List<CartItemModel> get marketItems =>
      _items.where((e) => e.type == CartItemType.market).toList();
  List<CartItemModel> get recycleItems =>
      _items.where((e) => e.type == CartItemType.recycle).toList();

  // Danh sách đã chọn
  List<CartItemModel> get selectedMarketItems =>
      marketItems.where((e) => isSelected(e.product.id, e.type)).toList();
  List<CartItemModel> get selectedRecycleItems =>
      recycleItems.where((e) => isSelected(e.product.id, e.type)).toList();

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
      // Tự động chọn sản phẩm mới thêm
      _selectedIds.add(_selectionKey(product.id, type));
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
        _selectedIds.remove(_selectionKey(productId, type));
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

  // === TÍNH TOÁN CHỈ TRÊN ITEMS ĐÃ CHỌN ===
  // Logic tính toán cho Chợ đồ cũ
  double get marketSubtotal => selectedMarketItems.fold(
    0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );
  double get shippingFee => selectedMarketItems.isEmpty ? 0 : 30000;
  double get totalMarketPrice => marketSubtotal + shippingFee;

  // Logic tính toán cho Gom rác (Ví dụ: 1kg rác = 1000 điểm)
  double get totalRecyclePoints =>
      selectedRecycleItems.fold(0, (sum, item) => sum + (item.quantity * 1000));

  void clearMarketOnly() {
    _items.removeWhere((e) => e.type == CartItemType.market);
    _selectedIds.removeWhere((key) => key.endsWith('_market'));
    notifyListeners();
  }
}
