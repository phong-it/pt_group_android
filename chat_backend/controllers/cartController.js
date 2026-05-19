// Cần import admin để dùng firestore (hoặc import db từ firebaseConfig của bạn)
const admin = require('firebase-admin');
const db = admin.firestore();

const syncCart = async (req, res) => {
    try {
        // req.user CHẮC CHẮN ĐÃ CÓ vì đã đi qua anh bảo vệ verifyToken
        const userId = req.user.uid;
        const { productId, quantity, type, price, name } = req.body;

        // Tạo ID duy nhất cho món hàng này trong giỏ
        const docId = `${userId}_${productId}`;
        const cartRef = db.collection('cart_items').doc(docId);

        if (quantity <= 0) {
            // Nếu số lượng <= 0, xóa luôn món đó khỏi Firebase
            await cartRef.delete();
        } else {
            // Nếu > 0, cập nhật hoặc thêm mới (set với merge: true)
            await cartRef.set({
                userId: userId,
                productId: productId,
                name: name,
                price: price,
                quantity: quantity,
                type: type,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
        }

        res.status(200).json({ message: "Đồng bộ giỏ hàng thành công!" });
    } catch (error) {
        console.error("Lỗi đồng bộ giỏ hàng:", error);
        res.status(500).json({ error: "Không thể lưu giỏ hàng" });
    }
};

module.exports = {
    syncCart
};