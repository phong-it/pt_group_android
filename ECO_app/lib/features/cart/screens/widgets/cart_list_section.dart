import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item_model.dart';
import 'cart_summary_footer.dart'; // Import file số 3

class CartListSection extends StatelessWidget {
  final CartItemType type;
  const CartListSection({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = type == CartItemType.market ? cart.marketItems : cart.recycleItems;

    final accentColor = type == CartItemType.market ? const Color(0xFFF3DFB3) : const Color(0xFFCBE3D6);

    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildCartItemCard(item, accentColor, cart);
                  },
                ),
        ),
        CartSummaryFooter(tabIndex: type == CartItemType.market ? 0 : 1),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Giỏ hàng trống',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item, Color accentColor, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildProductImage(item.product.imageUrls),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.product.description ?? "Khối lượng / Kích thước",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildCircleButton(
                              icon: Icons.remove,
                              onTap: item.quantity > 1 ? () => cart.updateQuantity(item.product.id, item.type, -1) : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                            _buildCircleButton(
                              icon: Icons.add,
                              isDark: true,
                              onTap: () => cart.updateQuantity(item.product.id, item.type, 1),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type == CartItemType.market 
                                ? Formatters.money(item.product.price) 
                                : 'Đổi Voucher',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
              onPressed: () {
                // Logic xóa item: cart.removeItem(item.product.id, item.type);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback? onTap, bool isDark = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : const Color(0xFFF0F0F0),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildProductImage(List<String>? urls) {
    if (urls != null && urls.isNotEmpty) {
      return Image.network(urls.first, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_outlined, color: Colors.grey)));
    }
    return const Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey));
  }
}