import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recycling_point_model.dart';
import '../../products/models/product_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapProvider extends ChangeNotifier {
  Position? currentPosition;
  List<RecyclingPointModel> recyclingPoints = [];
  List<ProductModel> products = [];

  StreamSubscription? _recyclingSub;
  StreamSubscription? _productSub;

  String _searchQuery = '';

  Set<Polyline> polylines = {};

  final String _googleApiKey = "AIzaSyDOqTkJNbInhFVYQHTMUfBHEpDVIh89dwI";

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

  // 2. Hàm gọi API và vẽ đường
  Future<void> drawRouteTo(double targetLat, double targetLng) async {
    if (currentPosition == null) return;

    double startLat = currentPosition!.latitude;
    double startLng = currentPosition!.longitude;

    // Gửi request xin đường đi từ Google
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$targetLat,$targetLng&key=$_googleApiKey";
    
    try {
      var response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        // Lấy chuỗi mã hóa Polyline từ cục JSON trả về
        String encodedPolyline = data['routes'][0]['overview_polyline']['points'];
        
        List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(encodedPolyline);
        
        // Chuyển đổi PointLatLng sang LatLng mà GoogleMap hiểu được
        List<LatLng> routeCoords = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        
        // Xóa đường cũ đi (nếu có) và tạo đường mới
        polylines.clear();
        polylines.add(
          Polyline(
            polylineId: const PolylineId("route_1"),
            color: Colors.blue, // Màu của đường đi
            width: 5, // Độ dày của đường
            points: routeCoords,
          ),
        );
        
        // Báo cho UI biết để vẽ lại!
        notifyListeners();
      } else {
        debugPrint("Lỗi từ Google API: ${data['status']} - ${data['error_message']}");
      }
    } catch (e) {
      debugPrint("Lỗi khi gọi API: $e");
    }
  }

  @override
  void dispose() {
    _recyclingSub?.cancel(); // Tắt luồng Firebase khi thoát map
    _productSub?.cancel();   // Tắt luồng Firebase khi thoát map
    super.dispose();
  }
}