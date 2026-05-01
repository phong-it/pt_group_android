import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/features/products/models/product_model.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // DÁN API KEY CỦA BẠN VÀO ĐÂY:
  final String _imgbbApiKey = 'ca1f6475cd3f814e5abc0556b6c1f210';

  // 1. HÀM PHỤ: Đẩy 1 ảnh lên ImgBB và lấy link về
  Future<String?> _uploadImageToImgBB(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
      );

      request.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: imageFile.name),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResult = json.decode(responseData);
        return jsonResult['data']['url'];
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
    required List<XFile> images,
    required double lat, // BẮT BUỘC TRUYỀN LAT
    required double lng, // BẮT BUỘC TRUYỀN LNG
  }) async {
    try {
      List<String> imageUrls = [];

      // Bước A: Vòng lặp đẩy từng ảnh lên ImgBB
      for (XFile image in images) {
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
    required List<XFile> newImages, // Bắt buộc người dùng phải chọn lại ảnh
    required double lat, // BẮT BUỘC TRUYỀN LAT
    required double lng, // BẮT BUỘC TRUYỀN LNG
  }) async {
    try {
      List<String> imageUrls = [];

      // Up lại toàn bộ ảnh mới lên ImgBB
      for (XFile image in newImages) {
        String? downloadUrl = await _uploadImageToImgBB(
          image,
        ); // Lời gọi hàm cũ của bạn
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

  // Hàm lấy Stream danh sách sản phẩm dựa trên danh mục
  Stream<List<ProductModel>> getProductsStream(String category) {
    Query query = _firestore.collection('products');

    // Nếu chọn danh mục cụ thể, Firebase sẽ lọc dùm mình
    if (category != 'Tất cả') {
      query = query.where('category', isEqualTo: category);
    } else {
      // Nếu là "Tất cả", sắp xếp theo ngày đăng mới nhất
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }
}
