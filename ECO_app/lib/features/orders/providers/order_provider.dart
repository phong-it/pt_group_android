import 'package:flutter/material.dart';
import '../models/order_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_config.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  OrderModel? _currentOrder;
  OrderModel? get currentOrder => _currentOrder;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage; // Thêm biến quản lý lỗi
  String? get errorMessage => _errorMessage;

  final String apiUrl = ApiConfig.baseUrl;

  void setCurrentOrderById(String id) {
    _currentOrder = _orders.firstWhere((o) => o.id == id);
    notifyListeners();
  }

  // Helper để tạo Header cho gọn
  Map<String, String> _getHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // 1. TẢI TOÀN BỘ DANH SÁCH (Dùng cho trang History)
  Future<void> fetchOrders(String token) async {
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/orders'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ordersData = responseData['data'];

        _orders = ordersData
            .map((item) => OrderModel.fromJson(item, item['id'] ?? item['_id']))
            .toList();
      }
    } catch (e) {
      print("Lỗi fetchOrders: $e");
    } finally {
      _setLoading(false);
    }
  }

  // 2. TẢI CHI TIẾT 1 ĐƠN HÀNG (Dùng cho trang Details)
  Future<void> fetchOrderById(String orderId, String token) async {
    _setLoading(true);

    // Tối ưu: Kiểm tra xem đơn hàng đã có sẵn trong List chưa để hiện ngay
    final existingOrder = _orders.indexWhere((o) => o.id == orderId);
    if (existingOrder != -1) {
      _currentOrder = _orders[existingOrder];
      // Vẫn nên gọi API để cập nhật status mới nhất từ server
    }

    try {
      // Senior Tip: Nên có API riêng /api/orders/$orderId
      final response = await http.get(
        Uri.parse('$apiUrl/orders'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ordersData = responseData['data'];
        print(
          "--- DEBUG: Danh sách đơn hàng từ Server có ${ordersData.length} mục ---",
        );

        final targetOrderJson = ordersData.firstWhere((item) {
          print("So sánh: ${item['id']} với $orderId"); // Xem nó có khớp không
          return item['id'] == orderId;
        }, orElse: () => null);

        if (targetOrderJson != null) {
          print("--- DEBUG: Đã tìm thấy đơn hàng! ---");
          _currentOrder = OrderModel.fromJson(targetOrderJson, orderId);
        } else {
          print("--- DEBUG: KHÔNG tìm thấy ID $orderId trong danh sách ---");
          _currentOrder = null;
        }
      }
    } catch (e) {
      print("Lỗi: $e");
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // 3. HỦY ĐƠN HÀNG (Đồng bộ cả 2 nơi)
  Future<void> cancelOrder(String token) async {
    if (_currentOrder == null) return;

    try {
      // Giả sử API hủy đơn của bạn là PUT hoặc POST
      // final response = await http.post(Uri.parse('$apiUrl/orders/${_currentOrder!.id}/cancel'), headers: _getHeaders(token));

      // Giả lập cập nhật Local sau khi API thành công
      _currentOrder!.status = OrderStatus.cancelled;

      // Cập nhật luôn trạng thái trong danh sách lịch sử mà không cần fetch lại
      int index = _orders.indexWhere((o) => o.id == _currentOrder!.id);
      if (index != -1) {
        _orders[index].status = OrderStatus.cancelled;
      }

      notifyListeners();
    } catch (e) {
      print("Lỗi hủy đơn: $e");
    }
  }

  // Helper quản lý loading cho chuyên nghiệp
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Hàm này giờ chỉ đóng vai trò dọn dẹp biến tạm trước khi vào trang chi tiết
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }
}
