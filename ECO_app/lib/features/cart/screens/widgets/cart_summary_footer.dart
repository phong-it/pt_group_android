import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';

class CartSummaryFooter extends StatelessWidget {
  final int tabIndex;
  const CartSummaryFooter({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isMarket = tabIndex == 0;
    final selectedCount = isMarket
        ? cart.selectedMarketItems.length
        : cart.selectedRecycleItems.length;
    final hasSelection = selectedCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Đã chọn $selectedCount sản phẩm',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row(
            'Tạm tính',
            isMarket
                ? Formatters.money(cart.marketSubtotal)
                : '${cart.totalRecyclePoints} pts',
          ),

          if (isMarket && hasSelection) ...[
            const SizedBox(height: 8),
            _row('Phí vận chuyển', Formatters.money(cart.shippingFee)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: _DottedSeparator(),
            ),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thành tiền',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                hasSelection
                    ? (isMarket
                        ? Formatters.money(cart.totalMarketPrice)
                        : '${cart.totalRecyclePoints} pts')
                    : '--',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCheckoutBtn(context, isMarket, hasSelection),
        ],
      ),
    );
  }

  Widget _row(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCheckoutBtn(BuildContext context, bool isMarket, bool hasSelection) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasSelection ? Colors.black : Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: hasSelection
            ? () => Navigator.pushNamed(context, AppRoutes.checkout)
            : null,
        child: Text(
          isMarket ? 'Thanh toán' : 'Đổi quà',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: hasSelection ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

// Chuyển thành Private Widget nằm chung file
class _DottedSeparator extends StatelessWidget {
  const _DottedSeparator();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black12),
              ),
            );
          }),
        );
      },
    );
  }
}
