const express = require('express');
const router = express.Router();

// 1. Import Middlewares
const verifyToken = require('../middlewares/authMiddleware');

// 2. Import Controllers
// CHỈ SỬA TẠI ĐÂY: Thêm hàm receivePayOSWebhook nhận từ checkoutController
const { processCheckout, receivePayOSWebhook } = require('../controllers/checkoutController');
const { syncCart } = require('../controllers/cartController');
const { getOrders, getOrderDetail } = require('../controllers/orderController'); // Thêm getOrderDetail
const shipperController = require('../controllers/shipperController');
// ==========================================
// 3. ĐỊNH NGHĨA CÁC ROUTES
// ==========================================

//Cổng tiếp nhận Webhook từ đối tác PayOS (Public - Không bọc verifyToken)
router.post('/payos-webhook', receivePayOSWebhook);

// Route thanh toán
router.post('/checkout', verifyToken, processCheckout);

// Route đồng bộ giỏ hàng (QUAN TRỌNG: Đã thêm verifyToken vào giữa)
router.post('/cart/sync', verifyToken, syncCart);

// API Lấy danh sách đơn hàng
router.get('/orders', verifyToken, getOrders); // <-- Gọi hàm getOrders

// API Lấy chi tiết một đơn hàng (Thêm mới)
router.get('/orders/:id', verifyToken, getOrderDetail);



// API: POST /api/shipper/update-status
router.post(
    '/shipper/update-status',
    shipperController.updateStatusByShipper
);

// Route dành cho shipper tra cứu đơn hàng bằng mã ECO-xxxx
router.get('/shipper/order/:orderCode', shipperController.getOrderByCode);


// Các route tương lai:
// router.post('/vouchers/redeem', verifyToken, redeemVoucherController);
// router.post('/eco/pickup', verifyToken, completePickupController);

// LUÔN ĐỂ LỆNH NÀY Ở DƯỚI CÙNG CỦA FILE
module.exports = router;