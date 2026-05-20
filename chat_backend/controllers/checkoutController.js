const { db, admin } = require("../config/firebaseConfig");
const { PayOS } = require("@payos/node");

// Khởi tạo SDK PayOS với object config
const payos = new PayOS({
  clientId: process.env.PAYOS_CLIENT_ID,
  apiKey: process.env.PAYOS_API_KEY,
  checksumKey: process.env.PAYOS_CHECKSUM_KEY,
});

if (!payos) {
  console.error(
    "❌ KHÔNG THỂ KHỞI TẠO PAYOS SDK. Kiểm tra environment variables.",
  );
}

/**
 * Logic 1: Xử lý đặt hàng (COD / Tạo QR bằng SDK PayOS chính chủ)
 */
const processCheckout = async (req, res) => {
  const userId = req.user.uid;
  const { voucherId, shippingAddress, paymentMethod } = req.body;

  try {
    const batch = db.batch();

    const cartSnapshot = await db
      .collection("cart_items")
      .where("userId", "==", userId)
      .get();
    if (cartSnapshot.empty) {
      return res.status(400).json({ error: "Giỏ hàng trống!" });
    }

    let totalAmount = 0;
    const items = [];

    cartSnapshot.forEach((doc) => {
      const data = doc.data();
      totalAmount += (data.price || 0) * data.quantity;
      items.push(data);
      batch.delete(doc.ref);
    });

    let discount = 0;
    if (voucherId) {
      const voucherRef = db.collection("vouchers").doc(voucherId);
      const voucherDoc = await voucherRef.get();
      if (
        voucherDoc.exists &&
        voucherDoc.data().status === "active" &&
        voucherDoc.data().userId === userId
      ) {
        discount = voucherDoc.data().discount_amount;
        batch.update(voucherRef, { status: "used" });
      } else {
        return res.status(400).json({ error: "Voucher không hợp lệ!" });
      }
    }

    let finalAmount = totalAmount - discount;
    if (finalAmount < 0) finalAmount = 0;

    const numericCode = Math.floor(100000 + Math.random() * 900000);
    const readableCode = `ECO-${numericCode}`;

    // GỌI SDK CỦA CỔNG PAYOS ĐỂ KHỞI TẠO ĐƠN HÀNG THANH TOÁN
    let qrData = null;
    if (paymentMethod === "QR_TRANSFER" && finalAmount > 0) {
      const paymentPayload = {
        orderCode: numericCode,
        amount: Math.round(finalAmount),
        description: `Thanh toan ECO`,
        cancelUrl: `https://google.com`,
        returnUrl: `https://google.com`,
      };

      // Hàm tạo link QR chính chủ từ SDK (Đã an toàn 100%)
      const paymentLinkData =
        await payos.paymentRequests.create(paymentPayload);

      qrData = {
        qrCode: paymentLinkData.qrCode,
        checkoutUrl: paymentLinkData.checkoutUrl,
        accountNumber: paymentLinkData.accountNumber || "N/A",
        accountName: paymentLinkData.accountName || "N/A",
      };
    }

    const orderRef = db.collection("orders").doc();
    batch.set(orderRef, {
      orderCode: readableCode,
      userId: userId,
      items: items,
      totalAmount: totalAmount,
      discount: discount,
      finalAmount: finalAmount,
      shippingAddress: shippingAddress || "Chưa cung cấp",
      paymentMethod: paymentMethod,
      status: "pending",
      paymentStatus: "unpaid",
      qrData: qrData,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    res.status(200).json({
      message: "Đặt hàng thành công!",
      orderId: orderRef.id,
      orderCode: readableCode,
      qrData: qrData,
      finalAmount: finalAmount,
    });
  } catch (error) {
    console.error("❌ [Lỗi tại luồng Checkout SDK]:", error);
    res.status(500).json({
      error: "Lỗi server khi thanh toán",
      message: error.message || error.toString(),
    });
  }
};

/**
 * Logic 2: Tiếp nhận cổng Webhook tự động từ PayOS gửi về khi nhận được tiền
 */
const receivePayOSWebhook = async (req, res) => {
  try {
    const webhookData = req.body;

    if (webhookData.confirm) {
      return res.status(200).json({ success: true });
    }

    // =====================================================================
    // 🌟 SỬ DỤNG SDK CHÍNH CHỦ: Tự dọn dẹp các trường rỗng và tự băm so khớp bảo mật
    // =====================================================================
    const verifiedData = await payos.webhooks.verify(webhookData);

    if (verifiedData) {
      const numericCode = verifiedData.orderCode;
      const readableCode = `ECO-${numericCode}`;

      const orderSnapshot = await db
        .collection("orders")
        .where("orderCode", "==", readableCode)
        .limit(1)
        .get();

      if (!orderSnapshot.empty) {
        const orderDoc = orderSnapshot.docs[0];

        await orderDoc.ref.update({
          status: "pending",
          paymentStatus: "paid",
          updated_at: new Date().toISOString(),
        });

        console.log(
          `[Webhook PayOS Success] Đơn hàng ${readableCode} đã kích hoạt trạng thái PAID thành công.`,
        );

        // PHÁT TÍN HIỆU REAL-TIME
        const io = req.app.get("socketio");
        if (io) {
          io.emit("orderStatusChanged", {
            orderId: orderDoc.id,
            status: "pending",
            paymentStatus: "paid",
          });
          console.log(
            `📡 [Socket Emit] Đã phát thông báo đổi trang thành công cho đơn: ${orderDoc.id}`,
          );
        }
      }
      return res.status(200).json({ success: true });
    }

    return res.status(400).send("Xác thực dữ liệu Webhook thất bại");
  } catch (error) {
    console.error("Lỗi xử lý hệ thống Webhook PayOS:", error);
    return res.status(400).send("Lỗi xử lý Webhook");
  }
};

module.exports = { processCheckout, receivePayOSWebhook };
