import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/cart/screens/cart_screen.dart';
import 'package:frontend/features/orders/screens/order_details_screen.dart';
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
import 'features/orders/providers/order_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'core/constants/app_routes.dart';
import 'features/checkout/screens/checkout_screen.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/chat/repositories/chat_repository.dart';
import 'features/chat/services/socket_service.dart';
import 'features/orders/screens/order_history_screen.dart';

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
        Provider(
          create: (_) {
            final service = SocketService();
            service.connect(); // <--- QUAN TRỌNG: Phải gọi ở đây
            return service;
          },
          dispose: (_, service) => service.dispose(), // Dọn dẹp khi app đóng
        ),

        // 2. Tạo Repository: ProxyProvider sẽ tự động update khi SocketService sẵn sàng
        ProxyProvider<SocketService, ChatRepository>(
          update: (_, socketService, __) => ChatRepository(socketService),
        ),

        // 3. Tạo ChatProvider: Phụ thuộc vào cả Repo và NotificationProvider
        ChangeNotifierProxyProvider3<
          ChatRepository,
          NotificationProvider,
          UserProvider, // Thêm UserProvider vào đây
          ChatProvider
        >(
          create: (context) => ChatProvider(
            context.read<ChatRepository>(),
            context.read<NotificationProvider>(),
            userProvider: context
                .read<UserProvider>(), // Truyền đúng tên tham số
          ),
          update: (context, repo, notif, user, previous) {
            // Nếu provider đã tồn tại, bạn có thể trả về nó hoặc tạo mới nếu các dependency thay đổi
            return previous ??
                ChatProvider(
                  repo,
                  notif,
                  userProvider: user, // Cập nhật UserProvider mới
                );
          },
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
        AppRoutes.orderHistory: (context) => const OrderHistoryScreen(),
      },

      home: const AuthScreen(), // Chạy vào màn hình điều hướng tổng
      debugShowCheckedModeBanner: false,
    );
  }
}
