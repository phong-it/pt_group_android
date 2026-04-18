import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat_message_model.dart';
import '../providers/chat_provider.dart';


class ChatScreen extends StatefulWidget {
  final String roomId;
  final String receiverName;

   ChatScreen({
    super.key,
    required this.roomId,
    required this.receiverName
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final String currentUserId = "0"; // Thay bằng ID thật từ Firebase Auth của bạn

  @override
  Widget build(BuildContext context) {
    final chatProv = context.read<ChatProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.receiverName),
        elevation: 1,
      ),
      body: Column(
        children: [
          // 1. Danh sách tin nhắn Real-time
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: chatProv.getMessagesStream(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text('Chưa có tin nhắn nào. Hãy bắt đầu trò chuyện!'));
                }

                return ListView.builder(
                  reverse: true, // Quan trọng: Đẩy tin mới nhất xuống dưới
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
          _buildInputArea(chatProv),
        ],
      ),
    );
  }

  // Widget hiển thị từng bong bóng tin nhắn
  Widget _buildMessageBubble(ChatMessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
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
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
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

  // Widget thanh nhập tin nhắn
  Widget _buildInputArea(ChatProvider chatProv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[300]!))),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  chatProv.sendMessage(
                    widget.roomId,
                    currentUserId,
                    _ctrl.text.trim(),
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