import 'package:flutter/material.dart';
import 'package:frontend/features/store_map/screens/map_screen.dart';

class QuickActions extends StatelessWidget {
  final Color primaryColor;

  const QuickActions({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.map,
        'label': 'Bản đồ',
        'color': Colors.blue,
        'onTap': () {
          // Điều hướng sang trang Bản đồ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MapScreen(), 
            ),
          );
        }
      },
      {
        'icon': Icons.local_activity_rounded,
        'label': 'Voucher',
        'color': Colors.orange
      },
      {
        'icon': Icons.local_shipping_rounded,
        'label': 'Đặt lịch gom',
        'color': primaryColor
      },
      {
        'icon': Icons.card_giftcard_rounded,
        'label': 'Đổi quà',
        'color': Colors.purple
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: actions.map((action) {
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: action['onTap'] as void Function()?,
            child: SizedBox(
              width: 76,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (action['color'] as Color).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}