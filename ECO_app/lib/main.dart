import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/cart/screens/cart_screen.dart';
import 'package:frontend/features/checkout/orders/screens/order_details_screen.dart';
import 'package:frontend/features/products/providers/product_provider.dart';
import 'package:frontend/features/profile/providers/user_provider.dart';
import 'package:frontend/features/store_map/providers/map_provider.dart';
import 'package:frontend/main_wrapper.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/screens/login_screen.dart';
import 'package:socket_io_client/socket_io_client.dart';

// Đảm bảo import đúng file chứa CartProvider của Phong
import 'features/cart/providers/cart_provider.dart';
import 'features/checkout/orders/providers/order_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'core/constants/app_routes.dart';
import 'features/checkout/screens/checkout_screen.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/chat/repositories/chat_repository.dart';
import 'features/chat/services/socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // --- PHẦN CHAT: Sắp xếp theo thứ tự phụ thuộc ---

        // 1. Tạo "Gốc": SocketService
        Provider(create: (_) => SocketService()),

        // 2. Tạo Repository: Lấy SocketService ở trên bỏ vào
        ProxyProvider<SocketService, ChatRepository>(
          update: (_, socketService, __) => ChatRepository(socketService),
        ),

        // 3. Tạo Provider: Lấy ChatRepository ở trên bỏ vào
        ChangeNotifierProxyProvider<ChatRepository, ChatProvider>(
          create: (context) => ChatProvider(context.read<ChatRepository>()),
          update: (context, repo, previous) => previous ?? ChatProvider(repo),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrade',
      theme: ThemeData(primarySwatch: Colors.green),

      routes: {
        // AppRoutes.checkout thực chất là chuỗi '/checkout'
        AppRoutes.checkout: (context) => const CheckoutScreen(),
        AppRoutes.home: (context) => const MainWrapper(),
        AppRoutes.orderDetail: (context) => const OrderDetailsScreen(),
        AppRoutes.cart: (context) => const CartScreen(),
      },

      home: const AuthScreen(), // Chạy vào màn hình điều hướng tổng
      debugShowCheckedModeBanner: false,
    );
  }
}
