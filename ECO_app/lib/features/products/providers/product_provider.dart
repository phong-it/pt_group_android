import 'dart:io';
import 'package:flutter/material.dart';
import '../service/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Hàm nội bộ để cập nhật trạng thái loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 1. C - CREATE (THÊM MỚI)
  Future<String?> addProduct({
    required String sellerId, 
    required String name, 
    required String category,
    required String description, 
    required double price, 
    required int conditionPercent,
    required List<File> images, 
    required double lat, 
    required double lng,
  }) async {
    _setLoading(true);
    final error = await _productService.uploadProduct(
      sellerId: sellerId, 
      name: name, 
      category: category, 
      description: description,
      price: price, 
      conditionPercent: conditionPercent, 
      images: images, 
      lat: lat, 
      lng: lng,
    );
    _setLoading(false);
    return error; // Trả về null nếu thành công, trả chuỗi nếu lỗi
  }

  // 2. U - UPDATE (CẬP NHẬT)
  Future<String?> updateProduct({
    required String productId, 
    required String name, 
    required String category,
    required String description, 
    required double price, 
    required int conditionPercent,
    required List<File> newImages, 
    required double lat, 
    required double lng,
  }) async {
    _setLoading(true);
    final error = await _productService.updateProduct(
      productId: productId, 
      name: name, 
      category: category, 
      description: description,
      price: price, 
      conditionPercent: conditionPercent, 
      newImages: newImages, 
      lat: lat, 
      lng: lng,
    );
    _setLoading(false);
    return error;
  }

  // 3. D - DELETE (XÓA)
  Future<String?> deleteProduct(String productId) async {
    _setLoading(true);
    final error = await _productService.deleteProduct(productId);
    _setLoading(false);
    return error;
  }
}