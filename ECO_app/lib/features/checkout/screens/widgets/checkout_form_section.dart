import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../cart/providers/cart_provider.dart';

class CheckoutFormSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TabController tabController;

  const CheckoutFormSection({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    // Thẻ cha duy nhất là SingleChildScrollView
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), // Hiệu ứng cuộn mượt
      padding: const EdgeInsets.only(bottom: 40), // Đệm đáy tránh lẹm chữ
      child: Column(
        children: [
          // THẺ THÔNG TIN NHẬN HÀNG
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin vận chuyển',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _buildModernTextField(nameController, 'Họ và tên', Icons.person_outline),
                const SizedBox(height: 12),
                _buildModernTextField(phoneController, 'Số điện thoại', Icons.phone_outlined, isPhone: true),
                const SizedBox(height: 12),
                _buildModernTextField(addressController, 'Địa chỉ nhận hàng', Icons.location_on_outlined, maxLines: 2),
              ],
            ),
          ),

          // TAB BAR PHƯƠNG THỨC THANH TOÁN
          TabBar(
            controller: tabController,
            indicatorColor: Colors.black,
            indicatorWeight: 2,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey.shade400,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Thanh toán COD'),
              Tab(text: 'Chuyển khoản QR'),
            ],
          ),
          
          // NỘI DUNG TAB (Dùng AnimatedBuilder, TUYỆT ĐỐI KHÔNG DÙNG EXPANDED Ở ĐÂY)
          AnimatedBuilder(
            animation: tabController,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: tabController.index == 0 
                    ? _buildCODTab() 
                    : _buildQRTab(context),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String hint, IconData icon, {bool isPhone = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        filled: true,
        fillColor: const Color(0xFFF0F2F5), // Màu nền xám siêu nhạt
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCODTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Giúp Column chỉ chiếm diện tích vừa đủ
        children: [
          Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Thanh toán bằng tiền mặt\nkhi nhận hàng',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQRTab(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Quét mã QR bên dưới để thanh toán',
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))
              ],
            ),
            child: Image.network(
              'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=CheckOut_Total_${cart.totalMarketPrice}',
              height: 180,
              width: 180,
            ),
          ),
        ],
      ),
    );
  }
}