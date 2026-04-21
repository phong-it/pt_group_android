import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recycling_point_model.dart';
import '../../products/models/product_model.dart';

class MapProvider extends ChangeNotifier {
  Position? currentPosition;
  List<RecyclingPointModel> recyclingPoints = [];
  List<ProductModel> products = [];

  StreamSubscription? _recyclingSub;
  StreamSubscription? _productSub;

  String _searchQuery = '';

  MapProvider() {
    _getCurrentLocation();
    _loadRecyclingPoints();
    _loadProductMarkers();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    currentPosition = await Geolocator.getCurrentPosition();
    notifyListeners();
  }

  void _loadRecyclingPoints() {
    _recyclingSub = FirebaseFirestore.instance.collection('recycling_points').snapshots().listen((snapshot) {
      recyclingPoints = snapshot.docs.map((doc) => RecyclingPointModel.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  void _loadProductMarkers() {
    _productSub = FirebaseFirestore.instance.collection('products').snapshots().listen((snapshot) {
      products = snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  // Getter để lấy danh sách sản phẩm đã được lọc
  List<ProductModel> get filteredProducts {
    if (_searchQuery.isEmpty) return products;
    return products.where((p) => 
      p.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  // Hàm cập nhật từ khóa tìm kiếm
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Hàm tính quãng đường (trả về String định dạng km)
  String calculateDistance(double targetLat, double targetLng) {
    if (currentPosition == null) return "N/A";
    
    double distanceInMeters = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      targetLat,
      targetLng,
    );

    if (distanceInMeters < 1000) {
      return "${distanceInMeters.toStringAsFixed(0)} m";
    } else {
      return "${(distanceInMeters / 1000).toStringAsFixed(1)} km";
    }
  }

  @override
  void dispose() {
    _recyclingSub?.cancel(); // Tắt luồng Firebase khi thoát map
    _productSub?.cancel();   // Tắt luồng Firebase khi thoát map
    super.dispose();
  }
}