import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../../cart/providers/cart_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../services/checkout_service.dart';
import '../../orders/models/order_model.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/formatters.dart';
import 'widgets/checkout_form_section.dart';
import 'widgets/checkout_summary_footer.dart';
import '../../profile/service/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/features/chat/services/socket_service.dart';

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

  // BIẾN TRẠNG THÁI HIỂN THỊ MÃ QR TẠI TAB KHÔNG ĐỔI TRANG
  QrDataModel? _generatedQrData;
  String? _createdOrderId;
  double _orderAmount = 0.0;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();

    _tabController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadUserProfile() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profileService = ProfileService();
    final userData = await profileService.getUserProfile(uid);

    if (userData != null && mounted) {
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _addressController.text = userData['address'] ?? '';
      });
    }
  }

  // KHỞI ĐỘNG BỘ LẮNG NGHE REAL-TIME QUA KÊNH CÓ SẴN CỦA SOCKET SERVICE
  void _startPaymentSocketListener(String orderId) {
    final socketService = context.read<SocketService>();
    _socketSubscription?.cancel();

    print("🎯 [CHECKOUT] Bắt đầu lắng nghe thanh toán cho đơn: $orderId");

    _socketSubscription = socketService.onOrderStatusChanged.listen(
      (data) {
        print("🔔 [CHECKOUT] Nhận được sự kiện socket: $data");

        final String incomingOrderId = data['orderId'].toString();
        final String paymentStatus = data['paymentStatus']?.toString() ?? '';
        final String status = data['status']?.toString() ?? '';

        print(
          "🔍 [CHECKOUT] Kiểm tra: incomingOrderId=$incomingOrderId, currentOrderId=$orderId, paymentStatus=$paymentStatus",
        );

        // Nếu đúng mã đơn hàng hiện tại và Backend báo đã trả tiền thành công
        if (incomingOrderId == orderId && paymentStatus == 'paid') {
          print("✅ [CHECKOUT] ĐƠN HÀNG ĐÃ THANH TOÁN! Chuyển trang...");
          _socketSubscription?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '🎉 Hệ thống đã nhận được tiền chuyển khoản! Đang điều hướng...',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );

            // TỰ ĐỘNG CHUYỂN HƯỚNG SANG TRANG CHI TIẾT ĐƠN HÀNG
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.orderDetail,
              arguments: orderId,
            );
          }
        }
      },
      onError: (error) {
        print("❌ [CHECKOUT] Lỗi socket listener: $error");
      },
    );
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(
    BuildContext context,
    String paymentMethod,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 🔴 CHÈN 2 DÒNG LỆNH PRINT DEBUG NÀY VÀO ĐỂ THEO DÕI TERMINAL FLUTTER:
      print("🚀 [FLUTTER DEBUG] NÚT ĐÃ BẤM - PHƯƠNG THỨC: $paymentMethod");
      String fullAddress =
          "${_nameController.text} - ${_phoneController.text} - ${_addressController.text}";

      final result = await _checkoutService.placeOrder(
        voucherId: _selectedVoucherId,
        shippingAddress: fullAddress,
        paymentMethod: paymentMethod,
      );

      // 🔴 CHÈN TIẾP DÒNG NÀY ĐỂ XEM ĐÚNG DỮ LIỆU GỐC TỪ SERVER:
      print("📦 [FLUTTER DEBUG] SERVER PHẢN HỒI JSON: $result");
      print("🔍 [FLUTTER DEBUG] KIỂM TRA TRƯỜNG qrData: ${result['qrData']}");

      if (!mounted) return;
      final cartProvider = context.read<CartProvider>();
      cartProvider.clearMarketOnly();

      // PHÂN TÁCH LUỒNG WORKFLOW ĐỘNG NGAY TẠI GIAO DIỆN
      if (paymentMethod == 'QR_TRANSFER' && result['qrData'] != null) {
        setState(() {
          _createdOrderId = result['orderId'];
          _generatedQrData = QrDataModel.fromJson(result['qrData']);

          // GIẢI PHÁP SỬA LỖI: Lấy số tiền sạch đã tính toán từ Backend trả về
          _orderAmount = (result['finalAmount'] ?? 0).toDouble();

          _isLoading = false;
        });

        // Kích hoạt cổng lắng nghe Real-time từ dòng tiền ngầm Webhook
        print(
          "🚀 [CHECKOUT] Gọi startPaymentSocketListener với orderId: ${_createdOrderId}",
        );
        _startPaymentSocketListener(_createdOrderId!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã khởi tạo mã VietQR chuyển khoản động!'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        // Nếu là COD -> Giữ nguyên luồng nhảy trực tiếp ban đầu
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công!')));
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.orderDetail,
          arguments: result['orderId'],
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      setState(() {
        _isLoading = false;
      });
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
            child: _generatedQrData != null
                ? _buildInTabQRSection(
                    _generatedQrData!,
                  ) // HIỂN THỊ MÃ QR THAY FORM KHI ĐÃ ĐẶT QR_TRANSFER
                : CheckoutFormSection(
                    nameController: _nameController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                    tabController: _tabController,
                  ),
          ),
          if (_generatedQrData == null)
            CheckoutSummaryFooter(
              isLoading: _isLoading,
              tabIndex: _tabController.index,
              onConfirm: _onConfirmOrder,
            )
          else
            _buildWaitingFooter(),
        ],
      ),
    );
  }

  // KHUNG VẼ MÃ VIETQR ĐỘNG NGAY TRÊN INTERFACE TAB THANH TOÁN
  Widget _buildInTabQRSection(QrDataModel qrInfo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2, color: Colors.green, size: 28),
                const SizedBox(width: 8), // ✅ Đã đổi thành SizedBox hợp lệ
                Text(
                  "Mã VietQR Chuyển Khoản",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Vui lòng quét mã dưới đây để hoàn tất đơn hàng số tiền ${_orderAmount.toStringAsFixed(0)}đ",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrInfo.qrCode,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SỐ TÀI KHOẢN (NGÂN HÀNG ẢO)",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        qrInfo.accountNumber,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: qrInfo.accountNumber),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã copy số tài khoản!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Sao chép",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "Hệ thống đang chờ bạn quét mã...",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade400,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Vui lòng thực hiện chuyển khoản, ứng dụng sẽ tự chuyển trang khi nhận được tiền.',
                ),
              ),
            );
          },
          child: const Text(
            "ĐANG CHỜ TIỀN VỀ REAL-TIME",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
