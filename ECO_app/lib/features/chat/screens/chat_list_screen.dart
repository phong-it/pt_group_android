import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: StreamBuilder<QuerySnapshot>(
        // Truy vấn tất cả phòng chat có chứa ID của tôi trong mảng members
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('members', arrayContains: currentUserId)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print('Lỗi cụ thể: ${snapshot.error}');
          if (snapshot.hasError)
            return const Center(child: Text('Đã xảy ra lỗi'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!.docs;

          if (rooms.isEmpty) {
            return const Center(
              child: Text('Bạn chưa có cuộc trò chuyện nào.'),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final roomData = rooms[index].data() as Map<String, dynamic>;
              final roomId = rooms[index].id;

              // Tìm ID của người kia để hiển thị tên (không phải ID của mình)
              final List<dynamic> members = roomData['members'];
              final receiverId = members.firstWhere(
                (id) => id != currentUserId,
              );

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  'Người dùng: $receiverId',
                ), // Sau này bạn dùng ID này để fetch tên thật
                subtitle: Text(
                  roomData['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        roomId: roomId,
                        receiverName: "Đang nhắn tin...",
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
