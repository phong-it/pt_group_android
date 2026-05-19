const { auth } = require("../config/firebaseConfig");

const verifyToken = async (req, res, next) => {
    const bearerHeader = req.headers['authorization'];

    if (!bearerHeader || !bearerHeader.startsWith('Bearer ')) {
        return res.status(403).json({ error: "Không tìm thấy token xác thực!" });
    }

    const token = bearerHeader.split(' ')[1];

    try {
        // Xác thực token với Firebase
        const decodedToken = await auth.verifyIdToken(token);

        // Gắn thông tin user vào request để các Controller phía sau dùng
        req.user = decodedToken;
        next(); // Cho phép đi tiếp
    } catch (error) {
        console.error("Lỗi xác thực Token:", error);
        return res.status(401).json({ error: "Token không hợp lệ hoặc đã hết hạn." });
    }
};

module.exports = verifyToken;