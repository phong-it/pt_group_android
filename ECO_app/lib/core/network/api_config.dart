import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _ip =
      "192.168.1.11"; // Đảm bảo IP này đang đúng với IP máy tính
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
