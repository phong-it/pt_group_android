import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
<<<<<<< HEAD
  static const String _ip = "192.168.1.11"; // Đảm bảo IP này đang đúng với IP máy tính
=======
  static const String _ip = "192.168.1.215"; // Đảm bảo IP này đang đúng với IP máy tính
>>>>>>> cd79272da2695df86e05e55f977e7eb3d845ca3e
  static const String _port = "3001";

  static String get baseUrl {
    if (kIsWeb) return "http://localhost:$_port/api";
    
    // Bỏ dòng kiểm tra Platform.isAndroid đi, dùng luôn IP LAN cho cả máy ảo và máy thật
    return "http://$_ip:$_port/api";
  }

  static String get socketUrl {
    if (kIsWeb) return "http://localhost:$_port";
    
    // Tương tự với Socket
    return "http://$_ip:$_port";
  }
}