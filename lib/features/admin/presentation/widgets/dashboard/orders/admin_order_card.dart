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
    final shortOrderId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final customerLabel = order.customerName.trim().isEmpty
        ? order.shortUserId
        : order.customerName.trim();
    final phoneLabel = order.phone.trim().isEmpty ? 'No phone' : order.phone.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORDER #${shortOrderId.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8E8E93),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.productName.isEmpty ? 'Unknown product' : order.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000000),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AdminStatusPill(
                  label: order.status.isEmpty ? 'placed' : order.status,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFF2F2F7)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _IconLabel(icon: Icons.person_outline_rounded, label: customerLabel),
                      _IconLabel(icon: Icons.phone_outlined, label: phoneLabel),
                      _IconLabel(icon: Icons.shopping_bag_outlined, label: 'Qty ${order.quantity}'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rs ${order.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF8E8E93)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.addressSummary.isEmpty ? 'No address provided' : order.addressSummary,
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF8E8E93)),
                const SizedBox(width: 4),
                Text(
                  adminTimeLabel(order.createdAt),
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                ),
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

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Color(0xFF3C3C43),
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
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
  String _userName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.order.userId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final name = data['name'] ?? data['username'] ?? data['displayName'] ?? 'Unknown User';
        if (mounted) setState(() => _userName = name.toString());
      } else {
        if (mounted) setState(() => _userName = 'Unknown User');
      }
    } catch (_) {
      if (mounted) setState(() => _userName = 'Unknown User');
    }
  }

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
    final customerName =
        o.customerName.trim().isEmpty ? _userName : o.customerName.trim();
    final phone = o.phone.trim().isEmpty ? 'Not provided' : o.phone.trim();
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
                    AdminInfoRow(
                        icon: Icons.receipt_long_outlined,
                        label: 'Order ID',
                        value: o.id.isEmpty ? '-' : o.id),
                    AdminInfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Customer',
                        value: customerName),
                    AdminInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: phone),
                    AdminInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'User ID',
                        value: o.userId),
                    AdminInfoRow(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Quantity',
                        value: '${o.quantity}'),
                    AdminInfoRow(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Unit Price',
                        value: 'Rs ${o.productPrice.toStringAsFixed(2)}'),
                    AdminInfoRow(
                        icon: Icons.payments_outlined,
                        label: 'Total',
                        value: 'Rs ${o.totalAmount.toStringAsFixed(2)}',
                        bold: true),
                    AdminInfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Ordered',
                        value: adminTimeLabel(o.createdAt)),
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
