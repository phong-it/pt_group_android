import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _ip = "192.168.1.15"; // Thay bằng IP máy tính của bạn
  static const String _port = "3001";

  // URL cho REST API (có /api)
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:$_port/api";
    if (Platform.isAndroid) return "http://10.0.2.2:$_port/api";
    // Dùng 10.0.2.2 cho máy ảo Android, nếu máy thật thì dùng $_ip
    return "http://$_ip:$_port/api";
  }

  // URL cho Socket (thường không có /api ở cuối)
  static String get socketUrl {
    if (kIsWeb) return "http://localhost:$_port";
    if (Platform.isAndroid) return "http://10.0.2.2:$_port";
    return "http://$_ip:$_port";
  }
}
