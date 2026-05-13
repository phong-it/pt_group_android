import CONFIG from './config.js';

/**
 * Hàm core để thực hiện các yêu cầu HTTP.
 * Giúp thống nhất cấu trúc phản hồi và xử lý lỗi hệ thống.
 */
async function apiRequest(endpoint, options = {}) {
    const url = `${CONFIG.API_URL}${endpoint}`;

    // Thiết lập default headers
    const defaultHeaders = { 'Content-Type': 'application/json' };

    const config = {
        ...options,
        headers: { ...defaultHeaders, ...options.headers }
    };

    try {
        const response = await fetch(url, config);

        // Parse JSON an toàn (tránh lỗi nếu server trả về chuỗi trống hoặc không phải JSON)
        let data = null;
        const contentType = response.headers.get("content-type");
        if (contentType && contentType.includes("application/json")) {
            data = await response.json();
        }

        if (!response.ok) {
            return {
                success: false,
                statusCode: response.status,
                message: data?.message || `Lỗi hệ thống: ${response.status}`,
                raw: data
            };
        }

        return {
            success: true,
            statusCode: response.status,
            data: data
        };

    } catch (error) {
        return {
            success: false,
            statusCode: 0,
            message: navigator.onLine ? `Lỗi kết nối: ${error.message}` : 'Mất kết nối Internet',
            error: error.message
        };
    }
}

export const ShipperService = {
    /**
     * Senior tip: Luôn sử dụng đúng tên biến tham chiếu (orderCode) 
     * để khớp với định nghĩa trong Express Route.
     */
    async getOrderByCode(orderCode) {
        // Nếu CONFIG.API_URL đã là "http://localhost:3001/api"
        // thì endpoint truyền vào chỉ cần bắt đầu bằng /shipper
        return await apiRequest(`/shipper/order/${orderCode}`, {
            method: 'GET'
        });
    },

    async updateStatus(orderId, status) {
        return await apiRequest('/shipper/update-status', {
            method: 'POST',
            body: JSON.stringify({ orderId, status })
        });
    }
};