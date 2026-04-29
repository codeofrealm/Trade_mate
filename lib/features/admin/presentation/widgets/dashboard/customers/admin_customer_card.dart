import 'package:flutter/material.dart';
import 'package:trade_mate/features/admin/data/models/admin_customer.dart';
import 'package:trade_mate/features/admin/utils/admin_customer_helpers.dart';

class AdminCustomerCard extends StatelessWidget {
  const AdminCustomerCard(
      {super.key, required this.customer, required this.onTap});
  final AdminCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final delivered = customer.orders.where((o) => o.isDelivered).length;
    final cancelled = customer.orders.where((o) => o.isCancelled).length;
    final firstLetter =
        customer.userId.isNotEmpty ? customer.userId[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(firstLetter,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.shortUserId,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF000000)),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _Badge(
                          label: '${customer.orders.length} orders',
                          color: const Color(0xFF007AFF)),
                      const SizedBox(width: 6),
                      if (delivered > 0)
                        _Badge(
                            label: '$delivered delivered',
                            color: const Color(0xFF34C759)),
                      if (cancelled > 0) ...[
                        const SizedBox(width: 6),
                        _Badge(
                            label: '$cancelled cancelled',
                            color: const Color(0xFFFF3B30)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRs(customer.totalSpent),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF000000)),
                ),
                const SizedBox(height: 2),
                const Text('spent',
                    style:
                        TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFC7C7CC), size: 18),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
