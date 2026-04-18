import 'package:flutter/material.dart';
import 'package:frontend/features/chat/screens/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Dùng lại thư viện load ảnh mượt
import '../models/product_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../../cart/models/cart_item_model.dart';
import '../service/product_service.dart';
import 'add_edit_product_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Biến theo dõi đang xem ảnh thứ mấy
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền xám nhạt
      
      // UX "HÀNG REAL": Dùng CustomScrollView để làm hiệu ứng cuộn dính (Sliver)
      body: CustomScrollView(
        slivers: [
          // 1. HEADER ẢNH SẢN PHẨM (Co giãn khi cuộn)
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black87),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Trượt để xem nhiều ảnh
                  widget.product.imageUrls.isNotEmpty
                      ? PageView.builder(
                          itemCount: widget.product.imageUrls.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
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
                  
                  // Nút hiển thị số thứ tự ảnh (VD: 1/3) giống Shopee
                  if (widget.product.imageUrls.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${widget.product.imageUrls.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. NỘI DUNG SẢN PHẨM
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
                      Text(
                        '${widget.product.price.toStringAsFixed(0)} đ',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      // Tag hiển thị Tình trạng & Danh mục
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

                const SizedBox(height: 10), // Khoảng hở xám

                // Khung thông tin Người Bán (Mockup UI chuẩn e-commerce)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Seller&background=random'),
                      ),
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green, side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {}, 
                        child: const Text('Xem trang'),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 10), // Khoảng hở xám

                // Khung Mô tả chi tiết
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mô tả chi tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        widget.product.description,
                        style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                      ),
                      const SizedBox(height: 30), // Đệm thêm khoảng trống ở dưới cùng
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 3. THANH CÔNG CỤ DÍNH Ở ĐÁY (Sticky Bottom Bar)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          // KIỂM TRA QUYỀN: Thay 'USER_123_DEMO' bằng ID thật lấy từ FirebaseAuth sau này
          child: (currentUserId == widget.product.sellerId) 
          
          // NẾU LÀ CHỦ SẢN PHẨM -> HIỆN NÚT SỬA / XÓA
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa tin'),
                    onPressed: () {
                      // Đẩy sang màn hình Đăng bán và "nhồi" dữ liệu hiện tại vào biến existingProduct
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddProductScreen(existingProduct: widget.product),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Xóa tin', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      // HIỆN HỘP THOẠI XÁC NHẬN TRƯỚC KHI XÓA (UX Hàng Real)
                      bool? confirm = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xóa tin đăng?'),
                          content: const Text('Bạn có chắc chắn muốn xóa món đồ này không? Không thể hoàn tác.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      // Nếu chọn Xóa
                      if (confirm == true) {
                        final error = await ProductService().deleteProduct(widget.product.id);
                        if (error == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thành công!'), backgroundColor: Colors.green));
                          Navigator.pop(context); // Thoát về trang chủ
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                        }
                      }
                    },
                  ),
                ),
              ],
            )
            
          // NẾU LÀ NGƯỜI MUA -> HIỆN NÚT CHAT / MUA HÀNG (Code cũ của bạn)
          : Row(
            children: [
              // Nút Chat
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.green, 
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    // 1. Giả lập ID của bạn (Sau này lấy từ Firebase Auth)
                    final String myUserId = "0"; 
                    
                    // 2. Lấy ID của người bán từ ProductModel (Kiểm tra xem model của bạn tên biến là gì nhé, ví dụ: sellerId)
                    final String sellerId = widget.product.sellerId ?? "unknown_seller";
                    
                    // 3. Lấy tên người bán để hiển thị lên thanh AppBar
                    final String sellerName = "Người bán"; 

                    // 4. Tạo mã phòng
                    final String roomId = _getRoomId(myUserId, sellerId);

                    // 5. Chuyển sang màn hình Chat của Phong
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          roomId: roomId,
                          receiverName: sellerName,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Nút Mua ngay / Thêm vào giỏ
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: const Text('Thêm vào giỏ hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: () {
                    final cart = Provider.of<CartProvider>(context, listen: false);
                    //final newItem = CartItem(
                      //productId: widget.product.id,
                      //title: widget.product.name,
                      //price: widget.product.price,
                      //sellerId: widget.product.sellerId,
                      //quantity: 1, 
                    //);
                    
                    // cart.addItem(newItem);
                    cart.addProduct(widget.product, CartItemType.market);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm vào giỏ hàng!'), backgroundColor: Colors.green),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tiện ích vẽ cái tag nhỏ
  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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

  // Thuật toán tạo Room ID chuẩn xác giữa 2 người
  String _getRoomId(String userId1, String userId2) {
    List<String> users = [userId1, userId2];
    users.sort(); // Sắp xếp theo alphabet để luôn ra 1 kết quả duy nhất
    return users.join('_'); // Kết quả ví dụ: "0_5"
  }
}