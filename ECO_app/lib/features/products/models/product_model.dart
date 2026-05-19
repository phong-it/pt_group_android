import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String sellerId;
  final String name; // Đổi từ title -> name
  final String category; // Thêm mới
  final String description;
  final double price;
  final int conditionPercent; // Đổi từ String -> int
  final String status;
  final List<String> imageUrls;
  final DateTime? createdAt;
  // THÊM 2 BIẾN TỌA ĐỘ 
  final double lat;
  final double lng;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.conditionPercent,
    required this.status,
    required this.imageUrls,
    required this.lat,
    required this.lng,
    this.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<String> images = [];
    if (data['imageUrls'] != null) { // Đã đổi thành imageUrls
      images = List<String>.from(data['imageUrls']);
    }

    return ProductModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '', // camelCase
      name: data['name'] ?? 'Chưa có tên',
      category: data['category'] ?? 'Khác',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      conditionPercent: (data['conditionPercent'] ?? 100).toInt(), // Mặc định 100% nếu thiếu
      status: data['status'] ?? 'available',
      imageUrls: images,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
    );
  }
}