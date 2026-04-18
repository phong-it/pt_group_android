import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../orders/models/order_model.dart';
import '../orders/providers/order_provider.dart';
import '../../../core/constants/app_routes.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Khởi tạo các controller để lấy dữ liệu từ người dùng
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

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
        appBar: AppBar(
          title: const Text('Thông tin thanh toán'),
        ),
        body: Column(
          children: [
            // PHẦN 1: Thông tin cá nhân (Nằm trên cùng)
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_nameController, 'Họ và tên', Icons.person),
                      const SizedBox(height: 10),
                      _buildTextField(_phoneController, 'Số điện thoại', Icons.phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 10),
                      _buildTextField(_addressController, 'Địa chỉ nhận hàng', Icons.location_on, maxLines: 2),
                    ],
                  ),
                ),
              ),
            ),

            // PHẦN 2: Thanh Tab chọn phương thức thanh toán
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: 'Thanh toán COD'),
                Tab(text: 'Chuyển khoản QR'),
              ],
            ),

            // PHẦN 3: Nội dung tương ứng của từng Tab
            Expanded(
              child: TabBarView(
                children: [
                  _buildCODTab(context),
                  _buildQRTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget dùng chung cho các ô nhập liệu
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}
      ) {
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

  // Giao diện Tab COD (Tối ưu từ phiên bản trước)
  Widget _buildCODTab(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSummaryCard(cart),
          const Spacer(),
          // Đã sửa: Thêm PaymentStatus tương ứng
          _buildConfirmButton(context, 'Xác nhận đặt hàng (COD)', Colors.orange, PaymentStatus.unpaid),
        ],
      ),
    );
  }

  // Giao diện Tab QR
  Widget _buildQRTab(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('Vui lòng quét mã QR bên dưới', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Image.network(
            'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=CheckOut_Total_${cart.totalMarketPrice}',
            height: 180,
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(cart),
          const SizedBox(height: 20),
          // Đã sửa: Thêm PaymentStatus tương ứng
          _buildConfirmButton(context, 'Tôi đã chuyển khoản', Colors.blue, PaymentStatus.paid),
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
            const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('${cart.totalMarketPrice.toStringAsFixed(0)}đ',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, String text, Color color, PaymentStatus paymentStatus) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        onPressed: () {
          // Kiểm tra xem đã nhập đủ thông tin chưa
          if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin nhận hàng')),
            );
            return;
          }
          // Đã sửa: Truyền đủ 2 tham số vào hàm
          _handlePaymentSuccess(context, paymentStatus);
        },
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _handlePaymentSuccess(BuildContext context, PaymentStatus paymentStatus) {
    // 0. Lấy các Provider cần thiết
    final orderProvider = context.read<OrderProvider>();
    final cartProvider = context.read<CartProvider>();
    final notifProvider = context.read<NotificationProvider>();

    // 1. Tạo đơn hàng mới
    final newOrder = OrderModel(
      id: "ORD${DateTime.now().millisecondsSinceEpoch}",
      customerName: _nameController.text,
      address: _addressController.text,
      totalAmount: cartProvider.totalMarketPrice,
      paymentStatus: paymentStatus,
    );

    // 2. Lưu vào Provider và kích hoạt chuỗi thông báo tự động
    orderProvider.createOrder(newOrder, notifProvider);

    // 3. Clear giỏ hàng
    cartProvider.clearMarketOnly();

    // 4. Chuyển hướng đến trang chi tiết đơn hàng
    // Chuyên gia khuyên dùng pushReplacementNamed để đồng bộ với AppRouter đã cài đặt
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.orderDetail,
    );
  }
}