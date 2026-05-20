const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, ".env") });

const express = require("express");
const cors = require("cors");
const http = require("http");
const socketIo = require("socket.io");
const apiRoutes = require("./routes");
const chatSocket = require("./sockets/chat");

const app = express();
const server = http.createServer(app);

// 1. Cấu hình các Middleware cơ bản của Express
app.use(cors({}));
app.use(express.json()); // Để đọc được body kiểu JSON

// 2. Tối ưu: Đưa Middleware ghi Log lên đầu để giám sát mọi request chuẩn xác
app.use((req, res, next) => {
  console.log(`>>> [API REQUEST] ${req.method} ${req.url}`);
  next();
});

// 3. Cấu hình hệ thống Socket.io Real-time
const io = socketIo(server, { cors: { origin: "*" } });

// Lưu biến IO vào app để các Controller khác có thể lấy ra sử dụng khi cần phát tín hiệu
app.set("socketio", io);
// Kích hoạt Socket cho tính năng Chat
chatSocket(io);

// Lắng nghe sự kiện kết nối Socket tổng quát
io.on("connection", (socket) => {
  console.log("🔌 Một thiết bị đã kết nối Socket: " + socket.id);
});

// 4. Kích hoạt toàn bộ hệ thống API Định tuyến (Routes)
// Cổng Webhook PayOS và các API khác đã được gom sạch vào đây
app.use("/api", apiRoutes);

// 5. Khởi động Server
const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`🚀 Server đang chạy mượt mà tại: http://localhost:${PORT}`);
});
