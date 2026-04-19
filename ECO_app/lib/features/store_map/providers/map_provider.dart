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

  @override
  void dispose() {
    _recyclingSub?.cancel(); // Tắt luồng Firebase khi thoát map
    _productSub?.cancel();   // Tắt luồng Firebase khi thoát map
    super.dispose();
  }
}