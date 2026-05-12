const { db } = require("../config/firebaseConfig");

const getOrders = async (req, res) => {
    try {
        // req.user.uid đã được verifyToken xác thực
        const userId = req.user.uid;

        // Truy vấn Firestore: Lấy đơn của user này và sắp xếp mới nhất lên đầu
        const ordersSnapshot = await db.collection('orders')
            .where('userId', '==', userId)
            .orderBy('created_at', 'desc')
            .get();

        const orders = [];
        ordersSnapshot.forEach(doc => {
            orders.push({
                id: doc.id, // Nhét cái ID thực tế của document vào
                ...doc.data() // Rải toàn bộ dữ liệu (orderCode, totalAmount...) vào object
            });
        });

        // Trả về cho Flutter
        res.status(200).json({ data: orders });
    } catch (error) {
        console.error("Lỗi lấy danh sách đơn hàng:", error);
        res.status(500).json({ error: "Không thể tải danh sách đơn hàng" });
    }
};

module.exports = { getOrders };