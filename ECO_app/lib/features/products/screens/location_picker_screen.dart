import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Mặc định là Đà Nẵng
  LatLng _centerPosition = const LatLng(16.0544, 108.2022); 
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Vừa vào thì cố gắng nhảy đến vị trí hiện tại cho tiện
    _getCurrentLocation(); 
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 3));
      setState(() => _centerPosition = LatLng(position.latitude, position.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLng(_centerPosition));
    } catch (e) {
      print('Bỏ qua lấy GPS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí bán', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _centerPosition, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            // SỰ KIỆN NÀY BẮT LẤY TỌA ĐỘ TÂM BẢN ĐỒ MỖI KHI NGƯỜI DÙNG VUỐT
            onCameraMove: (position) {
              _centerPosition = position.target; 
            },
            myLocationEnabled: true,
          ),
          
          // CÂY KIM MÀU ĐỎ CỐ ĐỊNH Ở CHÍNH GIỮA MÀN HÌNH
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Đẩy lên tí cho cái chóp nhọn chỉ đúng tâm
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
          ),

          // NÚT XÁC NHẬN DÍNH Ở ĐÁY
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Trả tọa độ vừa chốt về lại màn hình Form nhập liệu
                Navigator.pop(context, _centerPosition);
              },
              child: const Text('XÁC NHẬN VỊ TRÍ NÀY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}