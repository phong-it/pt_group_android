import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Thư viện mới
import 'package:frontend/features/products/providers/product_provider.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _selectedCategory = 'Tất cả';
  final List<String> _categories = ['Tất cả', 'Điện tử', 'Thời trang', 'Nội thất', 'Sách', 'Khác'];

  // Hàm Refresh giả lập hiệu ứng vuốt tải lại
  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {}); // Kích hoạt vẽ lại UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền xám nhạt để làm nổi bật các Card trắng
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.eco, color: Colors.green, size: 30),
            const SizedBox(width: 8),
            const Text('EcoTrade', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Colors.black87),
            onPressed: () {
              // TODO: Mở màn hình Chat
            },
          )
        ],
      ),
      body: Column(
        children: [
          // KHU VỰC 1: THANH TÌM KIẾM
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) {
                // Gọi Provider cập nhật từ khóa
                context.read<ProductProvider>().updateSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Bạn đang tìm đồ cũ gì?',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
          ),

          // KHU VỰC 2: THANH DANH MỤC TRƯỢT NGANG
          Container(
            color: Colors.white,
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    backgroundColor: Colors.grey[200],
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = category);
                    },
                  ),
                );
              },
            ),
          ),

          // KHU VỰC 3: DANH SÁCH SẢN PHẨM (Có Pull-to-refresh)
          Expanded(
            child: RefreshIndicator(
              color: Colors.green,
              onRefresh: _onRefresh,
              child: StreamBuilder<List<ProductModel>>(
                // Lấy Stream đã qua bộ lọc từ Provider
                stream: context.watch<ProductProvider>().getFilteredProducts(_selectedCategory),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.green));
                  }
                 // 1. Lấy danh sách sản phẩm ra (Nếu null thì gán bằng danh sách rỗng [])
                  final products = snapshot.data ?? [];

                  // 2. Kiểm tra nếu danh sách trống thì hiện màn hình trống
                  if (products.isEmpty) {
                    // Bạn có thể truyền thêm biến để biết là trống do "Không có đồ" hay "Tìm không thấy"
                    bool isSearching = context.read<ProductProvider>().searchQuery.isNotEmpty;
                    return _buildEmptyState(isSearch: isSearching);
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 cột
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7, // Tỷ lệ vàng cho Card sản phẩm
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(context, product, key: ValueKey(product.id),);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET CON: Hiển thị khi không có dữ liệu
  Widget _buildEmptyState({bool isSearch = false}) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Giữ cho vẫn có thể vuốt để refresh
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isSearch 
                ? 'Không tìm thấy sản phẩm bạn cần!' 
                : 'Chưa có món đồ nào trong mục này!', 
              style: TextStyle(color: Colors.grey[600])
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET CON: Thiết kế Card sản phẩm "Hàng Real"
  Widget _buildProductCard(BuildContext context, ProductModel product, {Key? key}) {
    return InkWell(
      key: key,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      width: double.infinity,
                      child: product.imageUrls.isNotEmpty
                          ? CachedNetworkImage( // Dùng thư viện load ảnh siêu mượt
                              imageUrl: product.imageUrls[0],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                              errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                            )
                          : Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50, color: Colors.grey)),
                    ),
                  ),
                  // Tag hiển thị độ mới
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                      child: Text('Mới ${product.conditionPercent}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            // Thông tin Text
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2, // Tối đa 2 dòng, quá thì hiện dấu ...
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.price.toStringAsFixed(0)} đ',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}