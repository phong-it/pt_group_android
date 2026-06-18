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

  // Quản lý bộ điều khiển cuộn
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Đăng ký lắng nghe sự kiện cuộn ngay khi màn hình khởi tạo
    _scrollController.addListener(_onScroll);

    // Kích hoạt nạp dữ liệu phòng chat an toàn qua microtask
    Future.microtask(() {
      if (mounted) {
        context.read<ChatProvider>().joinRoom(widget.roomId);
      }
    });
  }

  @override
  void dispose() {
    // Giải phóng tài nguyên chống leak bộ nhớ
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // Tự động kích hoạt tải thêm tin nhắn cũ khi cuộn gần lên đỉnh
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final currentScroll = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (currentScroll >= (maxScroll - 200)) {
      context.read<ChatProvider>().loadMoreMessages(widget.roomId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor:
          Colors.grey[100], // Nền xám nhẹ chuẩn UI các app chat hiện đại
      appBar: AppBar(
        title: Text(
          widget.receiverName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Thanh trạng thái khi mất kết nối mạng / đang kết nối lại
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: provider.isReconnecting ? 32 : 0,
            color: Colors.amber[700],
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

          // Danh sách hiển thị tin nhắn
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

  Widget _buildMessageItem(ChatMessageModel message, bool isMe) {
    return switch (message.type) {
      MessageType.text => _buildTextBubble(message, isMe),
      MessageType.image => _buildImageBubble(message, isMe),
      MessageType.system => _buildSystemMessage(message),
    };
  }

  // SENIOR FIX: Đã bọc Column vào Widget Padding để sửa lỗi biên dịch
  Widget _buildTextBubble(ChatMessageModel message, bool isMe) {
    final bool isSending = message.status == MessageStatus.sending;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: isSending ? 0.7 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ), // Đưa padding ra ngoài chuẩn chỉnh
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue[600] : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
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
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
              _buildMessageMetaInfo(message, isMe),
            ],
          ),
        ),
      ),
    );
  }

  // SENIOR FIX: Đã bọc Column vào Widget Padding để sửa lỗi biên dịch
  Widget _buildImageBubble(ChatMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ), // Đưa padding ra ngoài chuẩn chỉnh
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
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
      ),
    );
  }

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

  Widget _buildMessageMetaInfo(ChatMessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(message.sentAt),
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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
              Icon(Icons.check, size: 12, color: Colors.grey[500])
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

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendAction(),
                decoration: InputDecoration(
                  hintText: "Nhập tin nhắn...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.grey[100],
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
                onPressed: _handleSendAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSendAction() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    // Gọi hàm với bộ 2 tham số nghiệp vụ hạ tầng
    context.read<ChatProvider>().sendMessage(text, widget.roomId);
    _ctrl.clear();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }
}
