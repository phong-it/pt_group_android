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

  @override
  void initState() {
    super.initState();
    // Báo cho "Quản gia" Provider biết để dọn dẹp UI và gọi Repository
    Future.microtask(() {
      context.read<ChatProvider>().joinRoom(widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text(widget.receiverName), elevation: 1),
      body: Column(
        children: [
          // 1. Danh sách tin nhắn dùng Consumer
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProv, child) {
                final messages = chatProv.messages;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có tin nhắn nào. Hãy bắt đầu trò chuyện!',
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true, // Đẩy tin mới nhất xuống dưới
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    bool isMe = m.senderId == currentUserId;
                    return _buildMessageBubble(m, isMe);
                  },
                );
              },
            ),
          ),

          // 2. Thanh nhập liệu
          _buildInputArea(),
        ],
      ),
    );
  }

  // THÊM LẠI: Widget hiển thị từng bong bóng tin nhắn (Sửa lỗi 1)
  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
            child: Text(
              DateFormat('HH:mm').format(message.sentAt),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        ],
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

                  // Dùng context.read để gọi event mà không build lại toàn bộ UI
                  context.read<ChatProvider>().SendMessage(
                    DateTime.now().millisecondsSinceEpoch
                        .toString(), // Tạo ID ngẫu nhiên bằng Timestamp
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
