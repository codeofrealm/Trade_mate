import 'package:flutter/material.dart';
import 'package:trade_mate/features/admin/data/models/admin_user_order.dart';
import 'package:trade_mate/features/admin/utils/admin_customer_helpers.dart';

class AdminCustomerOrderCard extends StatelessWidget {
  const AdminCustomerOrderCard({super.key, required this.order});
  final AdminUserOrder order;

  @override
  Widget build(BuildContext context) {
    final statusColor = adminStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.productName.isEmpty ? 'Unknown product' : order.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF000000)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.isEmpty ? 'PLACED' : order.status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(order.productCategory,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 13, color: Color(0xFF8E8E93)),
              const SizedBox(width: 4),
              Text('Qty ${order.quantity}',
                  style: const TextStyle(
                      color: Color(0xFF8E8E93), fontSize: 12)),
              const Spacer(),
              Text('Rs ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF000000))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: Color(0xFFC7C7CC)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(order.addressSummary,
                    style: const TextStyle(
                        color: Color(0xFFC7C7CC), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(timeLabel(order.createdAt),
                  style: const TextStyle(
                      color: Color(0xFFC7C7CC), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
