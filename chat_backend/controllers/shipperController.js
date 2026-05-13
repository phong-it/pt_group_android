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
        const ordersRef = db.collection("orders");
        const querySnapshot = await ordersRef.where("orderCode", "==", orderId).limit(1).get();

        if (querySnapshot.empty) {
            return res.status(404).json({ success: false, message: "Không tìm thấy đơn hàng" });
        }

        const orderDoc = querySnapshot.docs[0];
        const currentData = orderDoc.data();
        const currentStatus = currentData.status;

        // 🚩 LOGIC CHIẾN LƯỢC: Ngăn chặn cập nhật đơn đã kết thúc
        if (currentStatus === "cancelled") {
            return res.status(400).json({
                success: false,
                message: "Không thể cập nhật đơn hàng đã bị hủy!"
            });
        }
        if (currentStatus === "delivered") {
            return res.status(400).json({
                success: false,
                message: "Đơn hàng đã giao thành công, không thể thay đổi trạng thái."
            });
        }

        // Senior Tip: Kiểm tra luồng logic (State Machine)
        // Ví dụ: Không thể nhảy từ "confirmed" lên "delivered" mà bỏ qua "shipping"
        const workflow = {
            'confirmed': ['picked_up', 'cancelled'],
            'picked_up': ['shipping', 'cancelled'],
            'shipping': ['delivered', 'cancelled'],
        };

        if (workflow[currentStatus] && !workflow[currentStatus].includes(status)) {
            return res.status(400).json({
                success: false,
                message: `Quy trình không hợp lệ. Không thể chuyển từ ${currentStatus} sang ${status}`
            });
        }

        // Cập nhật Database
        await orderDoc.ref.update({
            status: status,
            updated_at: new Date().toISOString(),
            updated_by_role: "shipper"
        });

        // 6. Thông báo qua Socket.io (Real-time)
        const io = req.app.get("socketio");
        if (io) {
            io.emit("order_status_changed", {
                orderId: orderId, // Trả về mã ECO để Frontend dễ nhận diện
                status: status,
                updateAt: new Date().toISOString(),
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

exports.getOrderByCode = async (req, res) => {
    try {
        const { orderCode } = req.params;
        const ordersRef = db.collection("orders");
        const querySnapshot = await ordersRef.where("orderCode", "==", orderCode.trim()).limit(1).get();

        if (querySnapshot.empty) {
            return res.status(404).json({ success: false, message: "Không tìm thấy đơn hàng" });
        }

        const orderData = querySnapshot.docs[0].data();

        // ĐẢM BẢO trả về đúng cấu trúc này
        return res.status(200).json({
            success: true,
            data: {
                orderCode: orderData.orderCode,
                status: orderData.status, // Đây là giá trị quan trọng nhất
                customerName: orderData.customerName || "Khách lẻ",
                totalAmount: orderData.totalAmount || 0
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: "Lỗi Server", error: error.message });
    }
};