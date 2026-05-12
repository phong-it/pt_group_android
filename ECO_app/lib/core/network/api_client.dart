import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  // Thay thế biến hằng (const) bằng một getter tự động tính toán
  static String get baseUrl {
    if (kIsWeb) {
      // Đang chạy trên Chrome / Web
      return 'http://127.0.0.1:3001/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Đang chạy trên máy ảo Android (Emulator)
      return 'http://10.0.2.2:3001/api';
    } else {
      // Đang chạy trên iOS Simulator hoặc thiết bị thật (cần điền IP thật ở đây)
      return 'http://192.168.1.X:3001/api';
    }
  }

  // Hàm nội bộ: Tự động tạo Header có chứa Token
  Future<Map<String, String>> _getHeaders() async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    try {
      // Lấy user hiện tại từ Firebase
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Lấy Token (Firebase tự động lo việc refresh nếu token hết hạn)
        String? token = await user.getIdToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token'; // Gắn chìa khóa vào đây!
        }
      }
    } catch (e) {
      print("Lỗi lấy token trong ApiClient: $e");
    }

    return headers;
  }

  // --- HÀM POST CHUẨN HÓA ---
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(); // Gọi hàm lấy header ở trên

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }

  // --- HÀM GET CHUẨN HÓA ---
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }

  // Hàm nội bộ: Xử lý kết quả trả về từ Node.js
  dynamic _handleResponse(http.Response response) {
    // 1. IN RA LOG ĐỂ XEM NODE.JS THỰC SỰ TRẢ VỀ GÌ
    print("========= KẾT QUẢ TỪ SERVER =========");
    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");
    print("=====================================");

    // 2. Kiểm tra nếu server trả về trang lỗi HTML thay vì JSON
    if (response.body.trim().startsWith('<!DOCTYPE html>') ||
        response.body.trim().contains('<html')) {
      throw Exception(
        'Lỗi Server: Node.js trả về trang HTML (Có thể bạn gọi sai link API hoặc server sập). Hãy check terminal Node.js!',
      );
    }

    // 3. Tiến hành Decode JSON an toàn
    try {
      final decodedBody = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedBody; // Thành công
      } else {
        // Quăng lỗi để màn hình UI bắt được
        String errorMessage = decodedBody['error'] ?? 'Có lỗi xảy ra từ server';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Bắt lỗi nếu dữ liệu không phải chuẩn JSON
      throw Exception('Dữ liệu server trả về bị lỗi định dạng: $e');
    }
  }
}
