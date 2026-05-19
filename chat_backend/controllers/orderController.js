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


const getOrderDetail = async (req, res) => {
    try {
        const orderId = req.params.id; // Lấy cái ID "d5TCj..." từ URL
        const userId = req.user.uid;    // Lấy ID người dùng từ Token (quan trọng!)

        const orderDoc = await db.collection('orders').doc(orderId).get();

        if (!orderDoc.exists) {
            return res.status(404).json({ error: "Không tìm thấy đơn hàng!" });
        }

        const orderData = orderDoc.data();

        // CHECK BẢO MẬT: Senior luôn kiểm tra quyền sở hữu
        if (orderData.userId !== userId) {
            return res.status(403).json({ error: "Bạn không có quyền xem đơn hàng này" });
        }

        res.status(200).json(orderData);

    } catch (error) {
        console.error("Lỗi lấy chi tiết đơn hàng:", error);
        res.status(500).json({ error: "Lỗi server" });
    }
};

module.exports = { getOrders, getOrderDetail };