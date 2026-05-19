import '../../../core/network/api_client.dart';

class CheckoutService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> placeOrder({
    String? voucherId,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post(
        '/checkout',
        body: {
          'voucherId': voucherId,
          'shippingAddress': shippingAddress,
          'paymentMethod': paymentMethod,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}