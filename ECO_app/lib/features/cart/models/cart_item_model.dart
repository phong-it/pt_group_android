import '../../products/models/product_model.dart';

enum CartItemType { market, recycle }

class CartItemModel {
  final ProductModel product;
  final int quantity;
  final CartItemType type;

  CartItemModel({
    required this.product,
    required this.quantity,
    required this.type,
  });
}