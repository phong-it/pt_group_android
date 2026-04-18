import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago; // Thư viện hiển thị thời gian
import '../../../core/constants/app_routes.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Cài đặt tiếng Việt cho thư viện timeago (Chạy 1 lần khi mở màn hình)
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages()); 
  }

 

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.items;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Nút "Đánh dấu tất cả đã đọc"
          TextButton(
            onPressed: () {
              // Gọi Provider lo việc cập nhật dữ liệu
              context.read<NotificationProvider>().markAllAsRead();
            },
            child: const Text('Đánh dấu đã đọc', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
      body: notifications.isEmpty
        ? const Center(child: Text('Bạn chưa có thông báo nào.'))
        : ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
            itemBuilder: (context, index) {
              final note = notifications[index]; // Lúc này note là một Object, không phải Map nữa
              
              // 3. Sửa lại cách gọi biến (Dùng dấu chấm thay vì ngoặc vuông)
              final isRead = note.isRead;
              final createdAt = note.createdAt;
              final timeString = timeago.format(createdAt, locale: 'vi');

              IconData iconData;
              Color iconColor;
              if (note.type == 'order') { // Dùng note.type thay vì note['type']
                iconData = Icons.local_shipping_outlined;
                iconColor = Colors.blue;
                } else if (note.type == 'eco_point') {
                  iconData = Icons.eco_outlined;
                  iconColor = Colors.green;
                } else {
                  iconData = Icons.chat_bubble_outline;
                  iconColor = Colors.orange;
                }

                return InkWell(
                  onTap: () {
                    // 4. Gọi hàm đánh dấu đã đọc từ Provider
                    context.read<NotificationProvider>().markAsRead(note.id);
                    // TODO: Navigator.push sang chi tiết đơn hàng nếu note.type == 'order'
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    // ĐỔI MÀU NỀN THEO TRẠNG THÁI: Chưa đọc thì nền xanh thật nhạt, Đã đọc thì nền trắng
                    color: isRead ? Colors.white : Colors.green.withOpacity(0.05),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cột 1: Icon tròn
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.grey[100] : iconColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: isRead ? Colors.grey : iconColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        
                        // Cột 2: Nội dung Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title,
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold, // Chưa đọc in đậm
                                  fontSize: 16,
                                  color: isRead ? Colors.black87 : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                note.body,
                                style: TextStyle(color: isRead ? Colors.grey[600] : Colors.black87, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timeString, // Hiển thị "5 phút trước"
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        
                        // Cột 3: Chấm xanh báo hiệu Chưa đọc (Nhỏ xíu ở góc phải)
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}