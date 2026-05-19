import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item_model.dart';
import '../../../products/models/product_model.dart';
import '../../../products/screens/product_detail_screen.dart';
import '../../../products/screens/widgets/product_card.dart';
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
              ? _buildEmptyWithSuggestions()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  children: [
                    // Header chọn tất cả
                    _buildSelectAllHeader(cart, items),
                    const SizedBox(height: 8),
                    // Danh sách sản phẩm trong giỏ
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCartItemCard(item, accentColor, cart),
                    )),
                    // Phần sản phẩm gợi ý
                    const SizedBox(height: 16),
                    _buildSuggestedProducts(context),
                  ],
                ),
        ),
        CartSummaryFooter(tabIndex: type == CartItemType.market ? 0 : 1),
      ],
    );
  }

  // === HEADER CHỌN TẤT CẢ ===
  Widget _buildSelectAllHeader(CartProvider cart, List<CartItemModel> items) {
    final allSelected = cart.isAllSelected(type);
    final selectedCount = cart.selectedCount(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) => cart.selectAll(type),
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Chọn tất cả ($selectedCount/${items.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // === EMPTY STATE VỚI GỢI Ý ===
  Widget _buildEmptyWithSuggestions() {
    return Builder(
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Giỏ hàng trống',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSuggestedProducts(context),
          ],
        );
      },
    );
  }

  // === CART ITEM CARD VỚI CHECKBOX ===
  Widget _buildCartItemCard(CartItemModel item, Color accentColor, CartProvider cart) {
    final isChecked = cart.isSelected(item.product.id, item.type);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isChecked
            ? Border.all(color: Colors.green.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isChecked,
              onChanged: (_) => cart.toggleSelection(item.product.id, item.type),
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),

          // Ảnh sản phẩm
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildProductImage(item.product.imageUrls),
            ),
          ),
          const SizedBox(width: 12),

          // Thông tin sản phẩm
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.product.category,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút +/- số lượng
                    Row(
                      children: [
                        _buildCircleButton(
                          icon: Icons.remove,
                          onTap: item.quantity > 1 ? () => cart.updateQuantity(item.product.id, item.type, -1) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    // Giá
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type == CartItemType.market
                            ? Formatters.money(item.product.price * item.quantity)
                            : 'Đổi Voucher',
                        style: const TextStyle(
                          fontSize: 12,
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

          // Nút xóa
          SizedBox(
            width: 28,
            child: IconButton(
              icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                cart.updateQuantity(item.product.id, item.type, -item.quantity);
              },
            ),
          ),
        ],
      ),
    );
  }

  // === SẢN PHẨM BẠN CÓ THỂ BIẾT ===
  Widget _buildSuggestedProducts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
              SizedBox(width: 6),
              Text(
                'Sản phẩm bạn có thể biết',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.green));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('Chưa có sản phẩm nào', style: TextStyle(color: Colors.grey.shade400)),
              );
            }

            final products = snapshot.data!.docs
                .map((doc) => ProductModel.fromFirestore(doc))
                .toList();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.68,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: products[index],
                  primaryColor: Colors.green,
                );
              },
            );
          },
        ),
      ],
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