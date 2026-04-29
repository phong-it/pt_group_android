const io = require("socket.io")(3001, {
    cors: { origin: "*" },
});

io.on("connection", (socket) => {
    console.log("User connected: " + socket.id);

    socket.on("join_room", (roomId) => {
        socket.join(roomId);
    });

    socket.on("send_message", (data) => {
        // data: { roomId, senderId, content, sentAt }
        io.to(data.roomId).emit("receive_message", data);
    });

    socket.on("disconnect", () => console.log("User disconnected"));
});