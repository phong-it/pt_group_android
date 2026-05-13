import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../services/checkout_service.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import 'widgets/checkout_form_section.dart'; // Import file số 2
import 'widgets/checkout_summary_footer.dart'; // Import file số 3

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  late TabController _tabController;
  bool _isLoading = false;
  final CheckoutService _checkoutService = CheckoutService();
  String? _selectedVoucherId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Cập nhật lại UI (Footer) khi đổi tab
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Logic xử lý API (Giữ nguyên như code của bạn)
  Future<void> _handlePaymentSuccess(
    BuildContext context,
    String paymentMethod,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String fullAddress =
          "${_nameController.text} - ${_phoneController.text} - ${_addressController.text} (PT: $paymentMethod)";

      final result = await _checkoutService.placeOrder(
        voucherId: _selectedVoucherId,
        shippingAddress: fullAddress,
      );

      if (!mounted) return;
      final cartProvider = context.read<CartProvider>();
      final notifProvider = context.read<NotificationProvider>();

      cartProvider.clearMarketOnly();
      // notifProvider.addNotification(...);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công!')));

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.orderDetail,
        arguments: result['orderId'],
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onConfirmOrder() {
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
    String method = _tabController.index == 0 ? 'COD' : 'QR_TRANSFER';
    _handlePaymentSuccess(context, method);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Checkout',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CheckoutFormSection(
              nameController: _nameController,
              phoneController: _phoneController,
              addressController: _addressController,
              tabController: _tabController,
            ),
          ),
          CheckoutSummaryFooter(
            isLoading: _isLoading,
            tabIndex: _tabController.index,
            onConfirm: _onConfirmOrder,
          ),
        ],
      ),
    );
  }
}
