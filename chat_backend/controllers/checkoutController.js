const { db, admin } = require("../config/firebaseConfig");

const processCheckout = async (req, res) => {
    const userId = req.user.uid;
    const { voucherId, shippingAddress } = req.body;

    try {
        const batch = db.batch();

        // 1. Lấy giỏ hàng từ Firestore
        const cartSnapshot = await db.collection('cart_items').where('userId', '==', userId).get();
        if (cartSnapshot.empty) {
            return res.status(400).json({ error: "Giỏ hàng trống!" });
        }

        let totalAmount = 0;
        const items = [];

        cartSnapshot.forEach(doc => {
            const data = doc.data();

            // FIX LỖI: Sử dụng data.price (như đã lưu ở cartController) thay vì selectedPrice
            const itemPrice = data.price || 0;
            totalAmount += (itemPrice * data.quantity);

            items.push(data);

            // Đưa lệnh xóa món hàng vào hàng đợi Batch
            batch.delete(doc.ref);
        });

        // 2. Xử lý Voucher (nếu có)
        let discount = 0;
        if (voucherId) {
            const voucherRef = db.collection('vouchers').doc(voucherId);
            const voucherDoc = await voucherRef.get();

            if (voucherDoc.exists && voucherDoc.data().status === 'active' && voucherDoc.data().userId === userId) {
                discount = voucherDoc.data().discount_amount;
                // Đánh dấu voucher đã dùng
                batch.update(voucherRef, { status: "used" });
            } else {
                return res.status(400).json({ error: "Voucher không hợp lệ hoặc đã được sử dụng!" });
            }
        }

        // 3. Tính tiền cuối cùng
        let finalAmount = totalAmount - discount;
        if (finalAmount < 0) finalAmount = 0;

        // 4. Tạo Order
        const orderRef = db.collection('orders').doc();

        // Cấp thêm 1 mã Code dễ đọc cho User (Ví dụ: ECO-847291)
        const readableCode = `ECO-${Math.floor(100000 + Math.random() * 900000)}`;

        batch.set(orderRef, {
            orderCode: readableCode,
            userId: userId,
            items: items,
            totalAmount: totalAmount,
            discount: discount,
            finalAmount: finalAmount,
            shippingAddress: shippingAddress || "Chưa cung cấp",
            status: "pending", // Trạng thái: Chờ xác nhận
            created_at: admin.firestore.FieldValue.serverTimestamp()
        });

        // 5. Thực thi toàn bộ (Batch Commit) - Xóa giỏ, update voucher, tạo order cùng 1 lúc!
        await batch.commit();

        res.status(200).json({
            message: "Đặt hàng thành công!",
            orderId: orderRef.id,
            orderCode: readableCode
        });

    } catch (error) {
        console.error("Lỗi Checkout:", error);
        res.status(500).json({ error: "Lỗi server khi thanh toán" });
    }
};

module.exports = { processCheckout };