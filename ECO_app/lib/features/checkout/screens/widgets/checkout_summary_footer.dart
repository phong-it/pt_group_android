import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../cart/providers/cart_provider.dart';

class CheckoutSummaryFooter extends StatelessWidget {
  final bool isLoading;
  final int tabIndex;
  final VoidCallback onConfirm;

  const CheckoutSummaryFooter({
    super.key,
    required this.isLoading,
    required this.tabIndex,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isCOD = tabIndex == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(color: Color(0xFFF8F9FA)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${cart.totalMarketPrice.toStringAsFixed(0)} đ',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const MyDottedSeparator(), // Tái sử dụng nét đứt
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                '${cart.totalMarketPrice.toStringAsFixed(0)} đ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Nút CTA
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: isLoading ? null : onConfirm,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
<<<<<<< HEAD
                      isCOD ? 'Xác nhận đặt hàng (COD)' : 'Đặt hàng',
=======
                      isCOD ? 'Xác nhận đặt hàng (COD)' : 'Tôi đã chuyển khoản',
>>>>>>> cd79272da2695df86e05e55f977e7eb3d845ca3e
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget nét đứt (Nếu bạn đã có ở file cart_summary_footer.dart thì có thể xóa ở đây và import sang nhé)
class MyDottedSeparator extends StatelessWidget {
  final double height;
  final Color color;

  const MyDottedSeparator({
    super.key,
    this.height = 1,
    this.color = Colors.black12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}
