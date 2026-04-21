import 'package:flutter/material.dart';
import 'package:frontend/features/store_map/service/product_preview_sheet.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../../products/screens/product_detail_screen.dart'; 

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  static const LatLng _initialPosition = LatLng(16.0544, 108.2022);

  // Hàm chuyển đổi Data từ Provider thành Marker trên bản đồ
  Set<Marker> _buildMarkers(MapProvider provider) {
    Set<Marker> markers = {};

    // 1. Marker Trạm rác (Màu xanh)
    for (var point in provider.recyclingPoints) {
      markers.add(Marker(
        markerId: MarkerId(point.id),
        position: LatLng(point.lat, point.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: point.name, snippet: 'Nhận: ${point.materialsAccepted.join(", ")}'),
      ));
    }

    // 2. Marker Sản phẩm (Màu cam)
    for (var product in provider.filteredProducts) {
      if (product.lat == 0.0 && product.lng == 0.0) continue;
      
      markers.add(Marker(
        markerId: MarkerId('product_${product.id}'),
        position: LatLng(product.lat, product.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: product.name, snippet: '${product.price.toStringAsFixed(0)} đ'),
        onTap: () async {
          // 1. Ẩn bàn phím ngay lập tức
          FocusScope.of(context).unfocus();
          
          // Gọi sang file UI Bottom Sheet vừa tách
          bool? shouldGoToDetail = await ProductPreviewSheet.show(context, product);
          if (shouldGoToDetail == true) {
            if (!context.mounted) return;
            await Future.delayed(const Duration(milliseconds: 300));
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)));
          }
        },
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MapProvider>(
        builder: (context, mapProvider, child) {
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(target: _initialPosition, zoom: 14),
                onMapCreated: (controller) => _mapController = controller,
                markers: _buildMarkers(mapProvider), // Tự động vẽ lại khi Provider báo có data mới
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),

              Positioned(
                top: 50, left: 20, right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                  child: TextField( 
                    onChanged: (value) => mapProvider.updateSearchQuery(value),
                    
                    decoration: const InputDecoration( // Bạn có thể thêm const vào đây nếu muốn tối ưu
                      hintText: 'Tìm điểm bán gần bạn...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.green),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 30, right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (mapProvider.currentPosition != null) {
                      _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(mapProvider.currentPosition!.latitude, mapProvider.currentPosition!.longitude)));
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.green),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}