import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/recycling_point_model.dart';
import '../../products/models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../products/screens/product_detail_screen.dart'; 

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  // THÊM 2 BIẾN NÀY
  StreamSubscription? _recyclingSub;
  StreamSubscription? _productSub;
  
  // Vị trí mặc định (Ví dụ: Đà Nẵng như trong database của bạn)
  static const LatLng _initialPosition = LatLng(16.0544, 108.2022);
  
  Map<MarkerId, Marker> _markers = {};
  Map<MarkerId, Marker> _productMarkers = {}; // Chứa Marker đồ cũ
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadRecyclingPoints();
    _loadProductMarkers();
  }

  // Hàm lấy vị trí hiện tại của người dùng
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  // Hàm lấy các trạm thu gom từ Firebase và tạo Marker
  void _loadRecyclingPoints() {
    _recyclingSub = FirebaseFirestore.instance.collection('recycling_points').snapshots().listen((snapshot) {
      Map<MarkerId, Marker> newMarkers = {};
      
      for (var doc in snapshot.docs) {
        final point = RecyclingPointModel.fromFirestore(doc);
        final markerId = MarkerId(point.id);
        
        final marker = Marker(
          markerId: markerId,
          position: LatLng(point.lat, point.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Màu xanh cho môi trường
          infoWindow: InfoWindow(
            title: point.name,
            snippet: 'Nhận: ${point.materialsAccepted.join(", ")}',
          ),
        );
        newMarkers[markerId] = marker;
      }

      setState(() {
        _markers = newMarkers;
      });
    });
  }

  // hàm lấy vị trí bán sp
  void _loadProductMarkers() {
    _productSub = FirebaseFirestore.instance.collection('products').snapshots().listen((snapshot) {
      Map<MarkerId, Marker> newMarkers = {};
      
      for (var doc in snapshot.docs) {
        final product = ProductModel.fromFirestore(doc); // Dùng Model bạn vừa sửa ở Bước 1
        
        // Lọc: Nếu chưa có tọa độ (0.0) thì bỏ qua, không in lên bản đồ
        if (product.lat == 0.0 && product.lng == 0.0) continue;

        final markerId = MarkerId('product_${product.id}'); // Thêm tiền tố để khỏi trùng ID với trạm rác
        
        final marker = Marker(
          markerId: markerId,
          position: LatLng(product.lat, product.lng),
          // DÙNG MÀU CAM để phân biệt với trạm rác (màu Xanh)
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), 
          infoWindow: InfoWindow(
            title: product.name,
            snippet: '${product.price.toStringAsFixed(0)} đ',
          ),
          
          onTap: () async {
            // 1. Mở thẻ xem nhanh và CHỜ người dùng thao tác
            bool? shouldGoToDetail = await _showProductPreview(product);

            // 2. Nếu người dùng bấm nút "Xem chi tiết" (thẻ trả về true)
            if (shouldGoToDetail == true) {
              
              // Kiểm tra an toàn: Nếu màn hình Map vẫn đang mở thì mới chuyển trang
              if (!context.mounted) return; 
              
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
              );
            }
          },
        );
        newMarkers[markerId] = marker;
      }

      setState(() {
        _productMarkers = newMarkers;
      });
    });
  }
  
  @override
  void dispose() {
    _mapController.dispose();
    _recyclingSub?.cancel(); // Tắt lắng nghe trạm rác
    _productSub?.cancel(); // Tắt lắng nghe đồ cũ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. LỚP BẢN ĐỒ
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _initialPosition, zoom: 14),
            onMapCreated: (controller) => _mapController = controller,
            //Gộp cả 2 danh sách Marker lại
            markers: Set<Marker>.of(_markers.values)..addAll(_productMarkers.values),
            myLocationEnabled: true, // Hiện chấm xanh vị trí của mình
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
          ),

          // 2. THANH TÌM KIẾM ĐÈ LÊN TRÊN 
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm điểm bán gần bạn...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.green),
                ),
              ),
            ),
          ),

          // 3. NÚT ĐỊNH VỊ NHANH
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.animateCamera(
                    CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude)),
                  );
                }
              },
              child: const Icon(Icons.my_location, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  // HÀM HIỂN THỊ THẺ XEM NHANH KHI BẤM VÀO MARKER
  Future<bool?> _showProductPreview(ProductModel product) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent, // Nền trong suốt để thấy phần bo góc
      isScrollControlled: true, 
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // Bo 2 góc trên
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Tự động co giãn theo chiều cao nội dung
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh nắm nhỏ ở trên cùng (UX gợi ý kéo)
              Center(
                child: Container(
                  width: 40, height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // Nội dung chính: Cột Trái (Ảnh) - Cột Phải (Thông tin)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ẢNH SẢN PHẨM
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100, height: 100,
                      child: product.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrls[0],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                            )
                          : Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // THÔNG TIN
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${product.price.toStringAsFixed(0)} đ',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        
                        // Tag độ mới
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('Mới ${product.conditionPercent}%', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // NÚT BẤM "XEM CHI TIẾT"
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // CHỈ CẦN 1 DÒNG DUY NHẤT: Đóng thẻ và gửi tín hiệu "true" ra ngoài
                  Navigator.pop(context, true); 
                },
                child: const Text('Xem chi tiết', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10), // Đệm thêm chút khoảng trống ở đáy
            ],
          ),
        );
      },
    );
  }
}