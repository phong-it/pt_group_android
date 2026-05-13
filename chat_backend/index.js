const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIo = require('socket.io');
const apiRoutes = require('./routes');
const chatSocket = require('./sockets/chat');

const app = express();
const server = http.createServer(app);

// Cấu hình Express
app.use(cors({}));
app.use(express.json()); // Để đọc được body kiểu JSON

// Cấu hình Socket.io
const io = socketIo(server, { cors: { origin: "*" } });

// LƯU IO VÀO APP (Để sử dụng trong Controller)
app.set('socketio', io);
// Kích hoạt Socket.io
chatSocket(io);

// Socket connection logic
io.on('connection', (socket) => {
    console.log('Một thiết bị đã kết nối: ' + socket.id);
});
// Kích hoạt REST API Routes
app.use('/api', apiRoutes);

app.use((req, res, next) => {
    console.log(`>>> Request tới: ${req.method} ${req.url}`);
    next();
});

// Khởi động Server
const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
});