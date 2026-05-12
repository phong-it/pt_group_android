import '../../../core/network/api_client.dart';

class CheckoutService {
  final ApiClient _apiClient = ApiClient();

  // Hàm gọi API thanh toán
  Future<Map<String, dynamic>> placeOrder({
    String? voucherId,
    required String shippingAddress,
  }) async {
    try {
      // CHÚ Ý: Không cần truyền Token hay UserId nữa, ApiClient và Backend đã tự lo!
      final response = await _apiClient.post(
        '/checkout', // Điểm đến API
        body: {'voucherId': voucherId, 'shippingAddress': shippingAddress},
      );

      return response; // Trả về data (VD: {message: "Thành công", orderId: "..."})
    } catch (e) {
      // Ném lỗi lên cho màn hình giao diện xử lý (hiện SnackBar)
      rethrow;
    }
  }
}
