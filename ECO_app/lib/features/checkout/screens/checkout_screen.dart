import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../orders/models/order_model.dart';
// Thay import của order_provider bằng checkout_service
import '../services/checkout_service.dart';
import '../../../core/constants/app_routes.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // THÊM: Biến trạng thái để hiển thị vòng xoay loading
  bool _isLoading = false;

  // THÊM: Khởi tạo Service để gọi API
  final CheckoutService _checkoutService = CheckoutService();

  // Giả sử bạn có biến này để lưu ID voucher người dùng chọn (có thể update sau)
  String? _selectedVoucherId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Thông tin thanh toán')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin nhận hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _nameController,
                        'Họ và tên',
                        Icons.person,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        _phoneController,
                        'Số điện thoại',
                        Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        _addressController,
                        'Địa chỉ nhận hàng',
                        Icons.location_on,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: 'Thanh toán COD'),
                Tab(text: 'Chuyển khoản QR'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [_buildCODTab(context), _buildQRTab(context)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildCODTab(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSummaryCard(cart),
          const Spacer(),
          _buildConfirmButton(
            context,
            'Xác nhận đặt hàng (COD)',
            Colors.orange,
            'COD',
          ),
        ],
      ),
    );
  }

  Widget _buildQRTab(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Vui lòng quét mã QR bên dưới',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Image.network(
            'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=CheckOut_Total_${cart.totalMarketPrice}',
            height: 180,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(cart),
          const SizedBox(height: 20),
          _buildConfirmButton(
            context,
            'Tôi đã chuyển khoản',
            Colors.blue,
            'QR_TRANSFER',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(CartProvider cart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tổng thanh toán:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${cart.totalMarketPrice.toStringAsFixed(0)}đ',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(
    BuildContext context,
    String text,
    Color color,
    String paymentMethod,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        // Nếu đang loading thì khóa nút, tránh user bấm 2 lần tạo 2 đơn
        onPressed: _isLoading
            ? null
            : () {
                if (_nameController.text.isEmpty ||
                    _addressController.text.isEmpty ||
                    _phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đầy đủ thông tin nhận hàng'),
                    ),
                  );
                  return;
                }
                // Gọi hàm xử lý Async
                _handlePaymentSuccess(context, paymentMethod);
              },
        // Hiển thị vòng xoay nếu đang chờ API
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // SỬA ĐỔI LỚN: Biến hàm này thành Future (Async) để gọi API Node.js
  Future<void> _handlePaymentSuccess(
    BuildContext context,
    String paymentMethod,
  ) async {
    // 1. Bật trạng thái Loading
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Gom thông tin địa chỉ lại thành chuỗi chi tiết
      String fullAddress =
          "${_nameController.text} - ${_phoneController.text} - ${_addressController.text} (PT: $paymentMethod)";

      // 3. Gọi API Node.js thông qua CheckoutService
      final result = await _checkoutService.placeOrder(
        voucherId: _selectedVoucherId, // Nếu có voucher thì truyền vào
        shippingAddress: fullAddress,
      );

      // 4. Nếu Server trả về thành công:
      final cartProvider = context.read<CartProvider>();
      final notifProvider = context.read<NotificationProvider>();

      // Xóa giỏ hàng trên App (Server đã xóa trên Firebase rồi)
      cartProvider.clearMarketOnly();

      // (Tùy chọn) Kích hoạt thông báo đẩy nội bộ trên App
      // notifProvider.addNotification(...);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công!')));

      // Chuyển hướng
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.orderDetail,
        arguments:
            result['orderId'], // Truyền ID đơn hàng thật từ Database sang
      );
    } catch (e) {
      // Bắt lỗi từ API (Ví dụ: hết hạn token, lỗi mạng, voucher sai...)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      // 5. Tắt trạng thái Loading dù thành công hay thất bại
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
