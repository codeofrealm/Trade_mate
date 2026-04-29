import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:trade_mate/features/admin/data/models/admin_user_order.dart';
import 'package:trade_mate/features/admin/utils/admin_helpers.dart';
import '../../shared/admin_shared_widgets.dart';

class AdminOrderCard extends StatelessWidget {
  const AdminOrderCard({super.key, required this.order, this.onTap});
  final AdminUserOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = adminStatusColor(order.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
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
                        fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF000000)),
                  ),
                ),
                AdminStatusPill(
                    label: order.status.isEmpty ? 'placed' : order.status,
                    color: statusColor),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              order.productCategory.isEmpty ? 'No category' : order.productCategory,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF8E8E93)),
                const SizedBox(width: 4),
                Text(order.shortUserId,
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                const SizedBox(width: 10),
                const Icon(Icons.shopping_bag_outlined, size: 14, color: Color(0xFF8E8E93)),
                const SizedBox(width: 4),
                Text('Qty ${order.quantity}',
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                const Spacer(),
                Text('Rs ${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Color(0xFF000000), fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFFC7C7CC)),
                const SizedBox(width: 4),
                Text(adminTimeLabel(order.createdAt),
                    style: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 11.5)),
                if (onTap != null) ...[
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFC7C7CC)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminOrderDetailSheet extends StatefulWidget {
  const AdminOrderDetailSheet({super.key, required this.order});
  final AdminUserOrder order;

  @override
  State<AdminOrderDetailSheet> createState() => _AdminOrderDetailSheetState();
}

class _AdminOrderDetailSheetState extends State<AdminOrderDetailSheet> {
  bool _isUpdating = false;

  static const _statuses = [
    'placed', 'processing', 'packed', 'shipped', 'delivered', 'cancelled',
  ];

  Future<void> _updateStatus(String s) async {
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({'status': s, 'updatedAt': FieldValue.serverTimestamp()});
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.productName.isEmpty ? 'Order Details' : o.productName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                        ),
                      ),
                      AdminStatusPill(
                          label: o.status.isEmpty ? 'placed' : o.status,
                          color: adminStatusColor(o.status)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(o.productCategory,
                      style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                  const SizedBox(height: 16),
                  AdminInfoCard(children: [
                    AdminInfoRow(label: 'Order ID', value: o.id.isEmpty ? '-' : o.id),
                    AdminInfoRow(label: 'User ID', value: o.shortUserId),
                    AdminInfoRow(label: 'Quantity', value: '${o.quantity}'),
                    AdminInfoRow(
                        label: 'Unit Price',
                        value: 'Rs ${o.productPrice.toStringAsFixed(2)}'),
                    AdminInfoRow(
                        label: 'Total',
                        value: 'Rs ${o.totalAmount.toStringAsFixed(2)}',
                        bold: true),
                    AdminInfoRow(label: 'Ordered', value: adminTimeLabel(o.createdAt)),
                  ]),
                  const SizedBox(height: 12),
                  AdminInfoCard(children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF007AFF)),
                        SizedBox(width: 6),
                        Text('Delivery Address',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF007AFF))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(o.addressSummary,
                        style: const TextStyle(color: Color(0xFF3C3C43), fontSize: 13.5)),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Update Status',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: -0.3)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statuses.map((s) {
                      final isCurrent = o.status.toLowerCase() == s;
                      final color = adminStatusColor(s);
                      return GestureDetector(
                        onTap: _isUpdating || isCurrent ? null : () => _updateStatus(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCurrent ? color : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isCurrent ? color : const Color(0xFFE5E5EA)),
                          ),
                          child: Text(
                            s[0].toUpperCase() + s.substring(1),
                            style: TextStyle(
                                color: isCurrent ? Colors.white : const Color(0xFF3C3C43),
                                fontWeight:
                                    isCurrent ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_isUpdating) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator.adaptive()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
