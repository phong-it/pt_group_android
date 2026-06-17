const { db, admin } = require("../config/firebaseConfig");

const chatSocket = (io) => {
    io.on("connection", (socket) => {
        console.log("User connected: " + socket.id);

        socket.on("join_room", (roomId) => {
            socket.join(roomId);
        });

        // ĐÂY LÀ ROOM CÁ NHÂN DÀNH CHO THÔNG BÁO 
        socket.on("join_user_room", (userId) => {
            if (userId) {
                socket.join(userId);
                console.log(`>>> User [${userId}] đã tham gia phòng nhận thông báo.`);
            }
        });

        socket.on("send_message", async (data) => {
            const { roomId, senderId, content } = data;
            const parts = roomId.split('_');
            const member1 = parts[0];
            const member2 = parts[1];
            const productId = parts[2] || "";

            await db.collection("chat_messages").add({
                roomId, senderId, content,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            await db.collection("chat_rooms").doc(roomId).set({
                lastMessage: content,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                members: [member1, member2],
                productId: productId
            }, { merge: true });

            socket.to(roomId).emit("receive_message", data);
        });

        socket.on("disconnect", () => console.log("User disconnected"));
    });
};

module.exports = chatSocket;