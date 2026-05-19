import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/features/products/models/product_model.dart';
import '../service/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  Future<String?> addProduct({
    required String sellerId,
    required String name,
    required String category,
    required String description,
    required double price,
    required int conditionPercent,
    required List<XFile> images,

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
    return error;
  }

  Future<String?> updateProduct({
    required String productId,
    required String name,
    required String category,
    required String description,
    required double price,
    required int conditionPercent,
    required List<XFile> images,
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
      newImages: images,
      lat: lat,
      lng: lng,
    );
    _setLoading(false);
    return error;
  }

  Future<String?> deleteProduct(String productId) async {
    _setLoading(true);
    final error = await _productService.deleteProduct(productId);
    _setLoading(false);
    return error;
  }

  Stream<List<ProductModel>> getFilteredProducts(String category) {
    return _productService.getProductsStream(category).map((products) {
      if (_searchQuery.isEmpty) return products;
      return products
          .where((p) => p.name.toLowerCase().contains(_searchQuery))
          .toList();
    });
  }
}
