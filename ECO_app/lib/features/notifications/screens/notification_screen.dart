import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_routes.dart';
import '../providers/notification_provider.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages()); 
    
    // Vẫn giữ initState làm phương án dự phòng khi màn hình được build lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // Tách hàm load data ra để tái sử dụng cho tính năng Pull-to-Refresh
  Future<void> _loadData() async {
    final notifProvider = context.read<NotificationProvider>();
    final authProvider = context.read<AuthProvider>();
    
    final currentUserId = authProvider.userId;
    
    if (currentUserId != null) {
      // Bỏ điều kiện kiểm tra isEmpty đi để ép buộc tải mới
      await notifProvider.fetchNotifications(currentUserId); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.items;
    
    // Giả sử provider của bạn có biến isLoading, nếu chưa có thì có thể bỏ qua
    // final isLoading = notifProvider.isLoading; 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: notifications.isEmpty ? null : () {
              context.read<NotificationProvider>().markAllAsRead();
            },
            child: Text(
              'Đánh dấu đã đọc', 
              style: TextStyle(color: notifications.isEmpty ? Colors.grey : Colors.green, fontWeight: FontWeight.w600)
            ),
          ),
        ],
      ),
      // THÊM TÍNH NĂNG VUỐT ĐỂ LÀM MỚI (Pull to Refresh)
      body: RefreshIndicator(
        color: Colors.green,
        onRefresh: _loadData, // Vuốt xuống sẽ tự động gọi lại API
        child: notifications.isEmpty
          ? Stack(
              children: [
                ListView(), // Phải có ListView trống để RefreshIndicator hoạt động
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.black26),
                      SizedBox(height: 16),
                      Text('Bạn chưa có thông báo nào.', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              // Thêm padding cho ListView để UI thoáng hơn
              padding: const EdgeInsets.symmetric(vertical: 8), 
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                final note = notifications[index]; 
                
                final isRead = note.isRead;
                final createdAt = note.createdAt;
                final timeString = timeago.format(createdAt, locale: 'vi');

                IconData iconData;
                Color iconColor;
                
                if (note.type == 'order_delivered') { 
                  iconData = Icons.local_shipping_outlined;
                  iconColor = Colors.blue;
                } else if (note.type == 'eco_point') {
                  iconData = Icons.eco_outlined;
                  iconColor = Colors.green;
                } else {
                  iconData = Icons.info_outline; // Đổi icon mặc định cho hợp lý hơn
                  iconColor = Colors.orange;
                }

                return Material(
                  color: isRead ? Colors.white : Colors.green.withOpacity(0.05),
                  child: InkWell(
                    onTap: () {
                      context.read<NotificationProvider>().markAsRead(note.id);
                      // TODO: Điều hướng sang chi tiết đơn hàng
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Tăng vertical padding
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12), // Tăng kích thước bọc icon
                            decoration: BoxDecoration(
                              color: isRead ? Colors.grey[100] : iconColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: isRead ? Colors.grey[400] : iconColor, size: 24),
                          ),
                          const SizedBox(width: 16), // Tăng khoảng cách giữa icon và text
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, 
                                    fontSize: 16,
                                    color: isRead ? Colors.black87 : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  note.body,
                                  style: TextStyle(
                                    color: isRead ? Colors.grey[600] : Colors.black87, 
                                    height: 1.4,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeString, 
                                  style: TextStyle(
                                    color: isRead ? Colors.grey[400] : Colors.green, // Nhấn mạnh thời gian nếu chưa đọc
                                    fontSize: 12,
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (!isRead)
                            Container(
                              margin: const EdgeInsets.only(top: 6, left: 8),
                              width: 10, // Tăng kích thước chấm xanh cho rõ
                              height: 10,
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}