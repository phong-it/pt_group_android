import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _centerPosition = const LatLng(16.0544, 108.2022); // Đà Nẵng mặc định
  GoogleMapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// Xử lý cấp quyền và lấy vị trí hiện tại chuyên nghiệp
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Dịch vụ định vị bị tắt.';

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw 'Quyền truy cập bị từ chối.';
      }

      if (permission == LocationPermission.deniedForever)
        throw 'Quyền bị từ chối vĩnh viễn.';

      Position position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 5),
      );
      _centerPosition = LatLng(position.latitude, position.longitude);

      _mapController?.animateCamera(CameraUpdate.newLatLng(_centerPosition));
    } catch (e) {
      debugPrint('Lỗi GPS: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ghim vị trí bán',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _centerPosition,
              zoom: 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (pos) => _centerPosition = pos.target,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Tự custom nút cho đẹp
            mapToolbarEnabled: false,
          ),

          // Custom Pin chính giữa màn hình (Senior thường dùng Widget thay vì Icon đơn thuần)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Ghim tại đây",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const Icon(Icons.location_on, size: 45, color: Colors.red),
                ],
              ),
            ),
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Nút xác nhận
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                onPressed: () => Navigator.pop(context, _centerPosition),
                child: const Text(
                  'XÁC NHẬN VỊ TRÍ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
