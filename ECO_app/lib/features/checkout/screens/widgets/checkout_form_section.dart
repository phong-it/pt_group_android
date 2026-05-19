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
    return Column(
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
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shipping Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                nameController,
                'Họ và tên',
                Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildModernTextField(
                phoneController,
                'Số điện thoại',
                Icons.phone_outlined,
                isPhone: true,
              ),
              const SizedBox(height: 12),
              _buildModernTextField(
                addressController,
                'Địa chỉ nhận hàng',
                Icons.location_on_outlined,
                maxLines: 2,
              ),
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Thanh toán COD'),
            Tab(text: 'Chuyển khoản QR'),
          ],
        ),

        // NỘI DUNG TAB (Expanded để lấp đầy khoảng trống còn lại)
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [_buildCODTab(), _buildQRTab(context)],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPhone = false,
    int maxLines = 1,
  }) {
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildCODTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Thanh toán bằng tiền mặt\nkhi nhận hàng',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRTab(BuildContext context) {
<<<<<<< HEAD
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Hệ thống sẽ tự động tạo mã VietQR động\nngay sau khi bạn nhấn đặt hàng.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              height: 1.4,
=======
    final cart = context.watch<CartProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Quét mã QR bên dưới để thanh toán',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.network(
              'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=CheckOut_Total_${cart.totalMarketPrice}',
              height: 180,
              width: 180,
>>>>>>> cd79272da2695df86e05e55f977e7eb3d845ca3e
            ),
          ),
        ],
      ),
    );
  }
}
