import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // DÁN API KEY CỦA BẠN VÀO ĐÂY:
  final String _imgbbApiKey = 'ca1f6475cd3f814e5abc0556b6c1f210';

  // 1. HÀM PHỤ: Đẩy 1 ảnh lên ImgBB và lấy link về
  Future<String?> _uploadImageToImgBB(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey')
      );
      
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResult = json.decode(responseData);
        return jsonResult['data']['url']; // Trả về link ảnh thật (https://i.ibb.co/...)
      }
      return null;
    } catch (e) {
      print('Lỗi up ảnh ImgBB: $e');
      return null;
    }
  }

  // 2. HÀM CHÍNH: Đăng sản phẩm
  Future<String?> uploadProduct({
    required String sellerId,
    required String name,
    required String category,
    required String description,
    required double price,
    required int conditionPercent,
    required List<File> images,
    required double lat, // BẮT BUỘC TRUYỀN LAT
    required double lng, // BẮT BUỘC TRUYỀN LNG
  }) async {
    try {
      
      List<String> imageUrls = [];

      // Bước A: Vòng lặp đẩy từng ảnh lên ImgBB
      for (File image in images) {
        String? downloadUrl = await _uploadImageToImgBB(image);
        if (downloadUrl != null) {
          imageUrls.add(downloadUrl);
        } else {
          return 'Lỗi khi tải ảnh lên máy chủ. Vui lòng thử lại!';
        }
      }

      // Bước B: Lưu toàn bộ thông tin (kèm link ảnh vừa lấy được) lên Firestore
      DocumentReference docRef = _firestore.collection('products').doc();

      await docRef.set({
        'sellerId': sellerId, 
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'conditionPercent': conditionPercent,
        'status': 'available',
        'imageUrls': imageUrls, 
        'lat': lat, // toạ độ
        'lng': lng,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Thành công
    } catch (e) {
      return 'Lỗi khi đăng sản phẩm: $e';
    }
   
  }
  // HÀM XÓA SẢN PHẨM
  Future<String?> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      return null; // Thành công
    } catch (e) {
      return 'Lỗi khi xóa sản phẩm: $e';
    }
  }
  
// 3. HÀM SỬA SẢN PHẨM (PHIÊN BẢN TỐI GIẢN: CHỈ DÙNG ẢNH MỚI)
  Future<String?> updateProduct({
    required String productId,
    required String name,
    required String category,
    required String description,
    required double price,
    required int conditionPercent,
    required List<File> newImages, // Bắt buộc người dùng phải chọn lại ảnh
    required double lat, // BẮT BUỘC TRUYỀN LAT
    required double lng, // BẮT BUỘC TRUYỀN LNG
  }) async {
    try {
      List<String> imageUrls = [];

      // Up lại toàn bộ ảnh mới lên ImgBB
      for (File image in newImages) {
        String? downloadUrl = await _uploadImageToImgBB(image); // Lời gọi hàm cũ của bạn
        if (downloadUrl != null) {
          imageUrls.add(downloadUrl);
        } else {
          return 'Lỗi khi tải ảnh lên máy chủ. Vui lòng thử lại!';
        }
      }

      // Cập nhật Firestore (Ghi đè luôn mảng imageUrls cũ bằng mảng mới)
      await _firestore.collection('products').doc(productId).update({
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'conditionPercent': conditionPercent,
        'imageUrls': imageUrls, 
        'lat': lat,
        'lng': lng,
      });

      return null; 
    } catch (e) {
      return 'Lỗi khi cập nhật sản phẩm: $e';
    }
  }
}