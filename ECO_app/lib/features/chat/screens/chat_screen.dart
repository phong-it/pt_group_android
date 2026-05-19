import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_message_model.dart';
import '../providers/chat_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? "khach_vang_lai";

  // SENIOR ADD: Quản lý bộ điều khiển cuộn
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Đăng ký lắng nghe sự kiện cuộn ngay khi màn hình khởi tạo
    _scrollController.addListener(_onScroll);

    // Báo cho "Quản gia" Provider biết để dọn dẹp UI và gọi Repository
    Future.microtask(() {
      context.read<ChatProvider>().joinRoom(widget.roomId);
    });
  }

  @override
  void dispose() {
    // CHỐT CHẶN RÒ RỈ BỘ NHỚ: Luôn giải phóng controller khi thoát màn hình
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // SENIOR IMPLEMENTATION: Hàm tính toán điểm kích hoạt tải thêm tin nhắn
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Lấy vị trí cuộn hiện tại
    final currentScroll = _scrollController.position.pixels;
    // Lấy giới hạn cuộn tối đa (đỉnh trên cùng của màn hình chat)
    final maxScroll = _scrollController.position.maxScrollExtent;

    // SENIOR UX TOUCH: Không đợi người dùng cuộn sát sạt lên đỉnh mới tải (gây ngắt quãng trải nghiệm).
    // Chúng ta đặt một ngưỡng kích hoạt sớm (Threshold) là 200 pixels trước khi chạm đỉnh.
    if (currentScroll >= (maxScroll - 200)) {
      // Gọi lệnh tải tin nhắn cũ từ Provider
      context.read<ChatProvider>().loadMoreMessages(widget.roomId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Phòng Chat chuẩn Senior")),
      body: Column(
        children: [
          // SENIOR UX DESIGN: Thanh trạng thái kết nối lại thông minh mượt mà
          AnimatedContainer(
            duration: const Duration(
              milliseconds: 300,
            ), // Hiệu ứng trượt xuống mượt mà 0.3s
            height: provider.isReconnecting
                ? 32
                : 0, // Tự động co giãn chiều cao theo trạng thái mạng
            color: Colors
                .amber[700], // Sắc cam chuẩn chỉ báo "Đang xử lý / Warning"
            width: double.infinity,
            child: provider.isReconnecting
                ? const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Đang kết nối lại...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Danh sách tin nhắn bên dưới thanh trạng thái
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount:
                        provider.messages.length +
                        (provider.isFetchingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final message = provider.messages[index];
                      final bool isMe = message.senderId == currentUserId;
                      return _buildMessageItem(message, isMe);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  // SENIOR REFACTOR: Hàm phân phối hiển thị giao diện theo từng loại tin nhắn độc lập
  Widget _buildMessageItem(ChatMessageModel message, bool isMe) {
    return switch (message.type) {
      MessageType.text => _buildTextBubble(message, isMe),
      MessageType.image => _buildImageBubble(message, isMe),
      MessageType.system => _buildSystemMessage(message),
    };
  }

  // Bong bóng hiển thị tin nhắn văn bản (Toàn bộ code cũ của hàm _buildMessageBubble được mang về đây)
  Widget _buildTextBubble(ChatMessageModel message, bool isMe) {
    final bool isSending = message.status == MessageStatus.sending;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: isSending ? 0.7 : 1.0,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 12),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            ),
            _buildMessageMetaInfo(
              message,
              isMe,
            ), // Hàm hiển thị thời gian + status (tách ra cho gọn)
          ],
        ),
      ),
    );
  }

  // SENIOR FUTURE-PROOF: Khung xương chuẩn bị sẵn cho tính năng hiển thị Ảnh (Story sau)
  Widget _buildImageBubble(ChatMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image, color: Colors.grey),
                SizedBox(width: 8),
                Text("[Tính năng Gửi ảnh đang phát triển]"),
              ],
            ),
          ),
          _buildMessageMetaInfo(message, isMe),
        ],
      ),
    );
  }

  // SENIOR FUTURE-PROOF: Khung xương chuẩn bị sẵn cho hiển thị Tin nhắn Hệ thống (Ví dụ: "X đã rời nhóm")
  // Tin nhắn hệ thống luôn căn giữa màn hình, không có khung bong bóng chat, chữ nghiêng màu xám nhạt
  Widget _buildSystemMessage(ChatMessageModel message) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message.content,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // Hàm helper hiển thị Giờ và Icon Trạng thái (Giúp tái sử dụng code ở Text và Image)
  Widget _buildMessageMetaInfo(ChatMessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(message.sentAt),
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            if (message.status == MessageStatus.sending)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
            else if (message.status == MessageStatus.sent)
              Icon(Icons.check, size: 12, color: Colors.grey[600])
            else if (message.status == MessageStatus.failed)
              GestureDetector(
                onTap: () =>
                    context.read<ChatProvider>().retrySendMessage(message.id),
                child: const Row(
                  children: [
                    Icon(Icons.refresh, size: 12, color: Colors.red),
                    SizedBox(width: 2),
                    Text(
                      "Gửi lại",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    // SENIOR DESIGN: Xác định độ mờ dựa trên trạng thái gửi
    final bool isSending = message.status == MessageStatus.sending;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        // Nếu đang gửi thì làm mờ đi một chút tạo hiệu ứng thị giác chuẩn Zalo
        opacity: isSending ? 0.7 : 1.0,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 12),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            ),

            // Hàng hiển thị Thời gian + Trạng thái gửi tin nhắn
            // Hàng hiển thị Thời gian + Trạng thái gửi tin nhắn
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.sentAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    if (message.status == MessageStatus.sending)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey,
                          ),
                        ),
                      )
                    else if (message.status == MessageStatus.sent)
                      Icon(Icons.check, size: 12, color: Colors.grey[600])
                    // SENIOR REFACTOR: Biến trạng thái lỗi thành nút bấm cứu hộ dữ liệu
                    else if (message.status == MessageStatus.failed)
                      GestureDetector(
                        onTap: () {
                          // Gọi hàm xử lý gửi lại, truyền ID duy nhất của tin nhắn vào
                          context.read<ChatProvider>().retrySendMessage(
                            message.id,
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.refresh, size: 12, color: Colors.red),
                            SizedBox(width: 2),
                            Text(
                              "Gửi lại",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SỬA LẠI: Nút gửi gọi đúng hàm handleSendMessage (Sửa lỗi 2)
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: "Nhập tin nhắn...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.grey[200],
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[600],
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  if (_ctrl.text.trim().isEmpty) return;

                  // SENIOR REFACTOR: UI bây giờ không cần tự tạo ID bằng Timestamp nữa.
                  // Việc "Vượt cấp" sinh ID ở UI đã được loại bỏ để tuân thủ tính đóng gói.
                  context.read<ChatProvider>().SendMessage(
                    _ctrl.text.trim(),
                    widget.roomId,
                    currentUserId,
                  );

                  _ctrl.clear();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
