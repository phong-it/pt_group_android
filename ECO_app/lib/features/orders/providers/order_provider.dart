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

  // Senior Tip: Viết hàm cập nhật trạng thái từ Socket
  void updateStatusFromSocket(String orderId, String newStatus) {
    if (_currentOrder != null &&
        (_currentOrder!.id == orderId || _currentOrder!.orderCode == orderId)) {
      _currentOrder!.status = OrderStatus.values.firstWhere(
        (e) => e.name == newStatus,
        orElse: () => _currentOrder!.status,
      );
      notifyListeners(); // UI tự động cập nhật mà không cần load lại trang
    }
  }

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

  // Thay vì fetch cả list, hãy yêu cầu Backend cung cấp API chi tiết
  Future<void> fetchOrderById(String orderId, String token) async {
    _setLoading(true);
    _errorMessage = null; // Reset lỗi cũ

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'),
        headers: _getHeaders(token),
      );

      // Senior Rule: Luôn kiểm tra StatusCode trước khi parse
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Kiểm tra xem dữ liệu nằm ở 'data' hay nằm trực tiếp ở root
        final dynamic rawData = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data']
            : decoded;

        if (rawData != null && rawData is Map<String, dynamic>) {
          _currentOrder = OrderModel.fromJson(rawData, orderId);
        } else {
          _errorMessage = "Định dạng dữ liệu không hợp lệ";
        }
      } else {
        // Xử lý các lỗi 404, 401, 500 một cách tường minh
        final errorData = json.decode(response.body);
        _errorMessage =
            errorData['error'] ?? "Lỗi không xác định (${response.statusCode})";
      }
    } catch (e) {
      _errorMessage =
          "Không thể kết nối tới máy chủ. Vui lòng kiểm tra internet.";
      debugPrint("Senior Log - fetchOrderById Error: $e");
    } finally {
      _setLoading(false);
      notifyListeners(); // Luôn notify để UI biết đã load xong hoặc có lỗi
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
