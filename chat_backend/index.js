
const admin = require("firebase-admin");
const serviceAccount = require("./config/serviceAccountKey.json"); // File key tải từ Firebase Console

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const io = require("socket.io")(3001, { cors: { origin: "*" } });

io.on("connection", (socket) => {
    console.log("User connected: " + socket.id);

    socket.on("join_room", (roomId) => {
        socket.join(roomId);
    });

    // Trong file chat_backend/index.js
    socket.on("send_message", async (data) => {
        const { roomId, senderId, content } = data; // Không cần chờ Flutter gửi productId nữa

        // TÁCH CHUỖI THÔNG MINH
        // roomId có dạng: "IDNgườiMua_IDNgườiBán_IDSảnPhẩm"
        const parts = roomId.split('_');
        const member1 = parts[0];
        const member2 = parts[1];
        const productId = parts[2] || ""; // Lấy ID sản phẩm ở khúc cuối

        // 1. Lưu tin nhắn (Giữ nguyên)
        await db.collection("chat_messages").add({
            roomId,
            senderId,
            content,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 2. Cập nhật phòng chat (SỬA Ở ĐÂY)
        await db.collection("chat_rooms").doc(roomId).set({
            lastMessage: content,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            members: [member1, member2], // CHỈ LƯU 2 NGƯỜI ĐỂ SAU NÀY QUERY CHO CHUẨN
            productId: productId // Đã lấy được ID sản phẩm chính xác
        }, { merge: true });

        // 3. Broadcast tin nhắn cho người còn lại
        socket.to(roomId).emit("receive_message", data);
    });

    socket.on("disconnect", () => console.log("User disconnected"));
});