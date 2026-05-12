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

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _row('Item total', isMarket ? Formatters.money(cart.totalMarketPrice) : '${cart.totalRecyclePoints} pts'),
          
          if (isMarket) ...[
            const SizedBox(height: 10),
            _row('Delivery fee', '30.000 ₫'),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: _DottedSeparator()),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                isMarket ? Formatters.money(cart.totalMarketPrice + 30000) : '${cart.totalRecyclePoints} pts',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCheckoutBtn(context, isMarket),
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

  Widget _buildCheckoutBtn(BuildContext context, bool isMarket) {
    return SizedBox(
      width: double.infinity, height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.checkout),
        child: Text(
          isMarket ? 'Thực hiện thanh toán' : 'Book Collection',
          style: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w600,
            color: Colors.white, 
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
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.black12)),
            );
          }),
        );
      },
    );
  }
}