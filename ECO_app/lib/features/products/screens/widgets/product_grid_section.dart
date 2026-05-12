import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Đảm bảo sửa lại đường dẫn import theo đúng dự án của bạn
import 'package:frontend/features/products/providers/product_provider.dart';
import '../../models/product_model.dart';
import 'product_card.dart';

class ProductGridSection extends StatelessWidget {
  final String selectedCategory;
  final Color primaryColor;

  const ProductGridSection({
    super.key,
    required this.selectedCategory,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: context.watch<ProductProvider>().getFilteredProducts(selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          bool isSearching = context.read<ProductProvider>().searchQuery.isNotEmpty;
          return _buildEmptyState(context, isSearch: isSearching);
        }

        return GridView.builder(
          shrinkWrap: true, // Cho phép nằm trong SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(), // Tắt cuộn độc lập
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              key: ValueKey(products[index].id),
              product: products[index],
              primaryColor: primaryColor,
            );
          },
        );
      },
    );
  }

  // Chuyển hàm EmptyState sang đây vì nó chỉ phục vụ cho khu vực sản phẩm
  Widget _buildEmptyState(BuildContext context, {bool isSearch = false}) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearch ? 'Không tìm thấy kết quả' : 'Chưa có sản phẩm',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Thử sử dụng từ khóa khác hoặc kiểm tra lại lỗi chính tả nhé.'
                : 'Danh mục này hiện tại chưa có món đồ nào được đăng bán.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}