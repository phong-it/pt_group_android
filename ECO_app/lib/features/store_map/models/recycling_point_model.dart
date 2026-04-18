import 'package:cloud_firestore/cloud_firestore.dart';

class RecyclingPointModel {
  final String id;
  final String name;
  final String address;
  final double lat; // Rút gọn từ latitude
  final double lng; // Rút gọn từ longitude
  final List<String> materialsAccepted; // Đổi từ accepted_materials

  RecyclingPointModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.materialsAccepted,
  });

  factory RecyclingPointModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<String> materials = [];
    if (data['materialsAccepted'] != null) {
      materials = List<String>.from(data['materialsAccepted']);
    }

    return RecyclingPointModel(
      id: doc.id,
      name: data['name'] ?? 'Trạm chưa có tên',
      address: data['address'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      materialsAccepted: materials,
    );
  }
}