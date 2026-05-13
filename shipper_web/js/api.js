import CONFIG from './config.js';

export const ShipperService = {
    async updateStatus(orderId, status) {
        const url = `${CONFIG.API_URL}/shipper/update-status`;
        console.log("Calling API:", url);

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ orderId, status })
            });
            //
            let data = null;
            try {
                data = await response.json();
            } catch { }

            if (!response.ok) {
                return {
                    success: false,
                    statusCode: response.status,
                    message: data?.message || data?.error || `Server trả về lỗi ${response.status}`,
                    raw: data
                };
            }

            return {
                success: true,
                statusCode: response.status,
                message: data?.message || 'Cập nhật thành công',
                data
            };
        } catch (error) {
            return {
                success: false,
                statusCode: 0,
                message: navigator.onLine ? `Không thể kết nối backend: ${error.message}` : 'Mất kết nối Internet',
                error: error.message
            };
        }
    }
};