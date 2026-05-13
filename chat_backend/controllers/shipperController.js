const { db } = require("../config/firebaseConfig");

exports.updateStatusByShipper = async (req, res) => {
    // Log để debug trong quá trình phát triển
    console.log(">>> [API] Shipper update request:", req.body);

    try {
        const { orderId, status } = req.body; // orderId ở đây là mã ECO-xxxxxx

        // 1. Kiểm tra đầu vào (Validation)
        if (!orderId || !status) {
            return res.status(400).json({
                success: false,
                message: "Thiếu thông tin orderId hoặc status",
            });
        }

        const allowedStatuses = ["confirmed", "picked_up", "shipping", "delivered", "cancelled"];
        if (!allowedStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: `Trạng thái '${status}' không hợp lệ.`,
            });
        }

        // 2. Truy vấn tìm Document có field 'orderCode' khớp với mã gửi lên
        // Senior Tip: Luôn dùng .limit(1) khi biết dữ liệu là duy nhất để tối ưu tốc độ truy vấn
        const ordersRef = db.collection("orders");
        const querySnapshot = await ordersRef.where("orderCode", "==", orderId).limit(1).get();

        // 3. Kiểm tra xem đơn hàng có tồn tại không
        if (querySnapshot.empty) {
            return res.status(404).json({
                success: false,
                message: `Không tìm thấy đơn hàng có mã: ${orderId}`,
            });
        }

        // 4. Lấy Document Reference từ kết quả truy vấn
        const orderDoc = querySnapshot.docs[0];
        const docRef = orderDoc.ref;
        const currentTime = new Date().toISOString();

        // 5. Cập nhật dữ liệu
        await docRef.update({
            status: status,
            updated_at: currentTime,
            updated_by_role: "shipper"
        });

        // 6. Thông báo qua Socket.io (Real-time)
        const io = req.app.get("socketio");
        if (io) {
            io.emit("order_status_changed", {
                orderId: orderId, // Trả về mã ECO để Frontend dễ nhận diện
                status: status,
                updateAt: currentTime,
            });
            console.log(`>>> [Socket] Đã phát tin hiệu đổi trạng thái cho đơn: ${orderId}`);
        }

        // 7. Trả về kết quả thành công
        return res.status(200).json({
            success: true,
            message: "Cập nhật trạng thái đơn hàng thành công",
            data: {
                orderCode: orderId,
                newStatus: status
            }
        });

    } catch (error) {
        console.error("❌ Lỗi nghiêm trọng tại updateStatusByShipper:", error);
        return res.status(500).json({
            success: false,
            message: "Lỗi hệ thống khi cập nhật đơn hàng",
            error: error.message,
        });
    }
};