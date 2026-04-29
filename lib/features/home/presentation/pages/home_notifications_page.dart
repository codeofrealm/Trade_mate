import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../data/models/home_user_order.dart';
import 'order_details_page.dart';

class HomeNotificationsPage extends StatelessWidget {
  const HomeNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: uid == null
          ? const Center(child: Text('Please login.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                }

                // Only delivered and cancelled
                final orders = snap.data!.docs
                    .map((d) =>
                        HomeUserOrder.fromFirestore(d.id, d.data()))
                    .where((o) => o.isDelivered || o.isCancelled)
                    .toList()
                  ..sort((a, b) =>
                      (b.updatedAt ?? b.createdAt ?? DateTime(0))
                          .compareTo(
                              a.updatedAt ?? a.createdAt ?? DateTime(0)));

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5EA),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF8E8E93),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No notifications yet',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF000000)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Delivered and cancelled orders\nwill appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF8E8E93), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _NotifCard(order: orders[index]),
                );
              },
            ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.order});
  final HomeUserOrder order;

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.isDelivered;
    final color =
        isDelivered ? const Color(0xFF34C759) : const Color(0xFFFF3B30);
    final icon = isDelivered
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
    final title = isDelivered ? 'Order Delivered' : 'Order Cancelled';
    final subtitle = order.productName.isEmpty
        ? 'Your order has been ${isDelivered ? 'delivered' : 'cancelled'}.'
        : '${order.productName} has been ${isDelivered ? 'delivered successfully' : 'cancelled'}.';

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.orderDetails,
        arguments: order,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E5EA)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF000000)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Color(0xFF8E8E93), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Rs ${order.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${_timeAgo(order.updatedAt ?? order.createdAt)}',
                        style: const TextStyle(
                            color: Color(0xFFC7C7CC), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFC7C7CC), size: 18),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime? value) {
  if (value == null) return '';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return '1 day ago';
  return '${diff.inDays} days ago';
}
