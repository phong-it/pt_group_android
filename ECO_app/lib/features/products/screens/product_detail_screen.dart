import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../service/product_bottom_detail.dart';  

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          // 1. HEADER ẢNH SẢN PHẨM
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black87),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  widget.product.imageUrls.isNotEmpty
                      ? PageView.builder(
                          itemCount: widget.product.imageUrls.length,
                          onPageChanged: (index) => setState(() => _currentImageIndex = index),
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: widget.product.imageUrls[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            );
                          },
                        )
                      : Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.image, size: 50))),
                  
                  if (widget.product.imageUrls.length > 1)
                    Positioned(
                      bottom: 16, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                        child: Text('${_currentImageIndex + 1}/${widget.product.imageUrls.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. NỘI DUNG THÔNG TIN
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Khung thông tin giá & tên
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.product.price.toStringAsFixed(0)} đ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 8),
                      Text(widget.product.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.3)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTag(Icons.category, widget.product.category, Colors.blue),
                          const SizedBox(width: 10),
                          _buildTag(Icons.verified, 'Mới ${widget.product.conditionPercent}%', Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Khung người bán (Mockup)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Seller&background=random')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Người bán ẩn danh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('ID: ${widget.product.sellerId.substring(0, 8)}...', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        onPressed: () {}, child: const Text('Xem trang'),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Khung Mô tả
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mô tả chi tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(widget.product.description, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
                      const SizedBox(height: 30), 
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ĐÂY LÀ ĐIỂM ĂN TIỀN: Gọi cái file thứ 2 ra đây
      bottomNavigationBar: ProductBottomBar(product: widget.product),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}