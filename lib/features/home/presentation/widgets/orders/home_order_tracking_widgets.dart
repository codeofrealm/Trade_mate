import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/models/home_user_order.dart';
import 'package:trade_mate/features/home/utils/home_helpers.dart';

// ── Orders summary card ───────────────────────────────────────────────────────

class HomeOrdersSummaryCard extends StatelessWidget {
  const HomeOrdersSummaryCard({
    super.key,
    required this.total,
    required this.active,
    required this.delivered,
    required this.cancelled,
  });

  final int total;
  final int active;
  final int delivered;
  final int cancelled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _SummaryItem(label: 'Total', value: '$total'),
          _SummaryDivider(),
          _SummaryItem(label: 'Active', value: '$active'),
          _SummaryDivider(),
          _SummaryItem(label: 'Delivered', value: '$delivered'),
          _SummaryDivider(),
          _SummaryItem(label: 'Cancelled', value: '$cancelled'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFCBD5E1), fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: const Color(0x33475569));
}

// ── Notification banner ───────────────────────────────────────────────────────

class HomeNotifBanner {
  const HomeNotifBanner(
      {required this.id, required this.message, required this.color});
  final String id;
  final String message;
  final Color color;
}

class HomeBannerCard extends StatelessWidget {
  const HomeBannerCard({super.key, required this.banner, required this.onDismiss});
  final HomeNotifBanner banner;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: banner.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: banner.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(banner.message,
                style: TextStyle(
                    color: banner.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 18, color: banner.color),
          ),
        ],
      ),
    );
  }
}

// ── Order tracking card ───────────────────────────────────────────────────────

class HomeOrderTrackingCard extends StatefulWidget {
  const HomeOrderTrackingCard({
    super.key,
    required this.order,
    required this.onTrack,
    required this.onCall,
    required this.onMessage,
    this.onProductTap,
  });

  final HomeUserOrder order;
  final VoidCallback onTrack;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback? onProductTap;

  @override
  State<HomeOrderTrackingCard> createState() => _HomeOrderTrackingCardState();
}

class _HomeOrderTrackingCardState extends State<HomeOrderTrackingCard> {
  bool _isCancelling = false;

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: Color(0xFFFF3B30)))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isCancelling = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final expectedDate =
        (order.createdAt ?? DateTime.now()).add(const Duration(days: 2));
    final canCancel = !order.isCancelled && !order.isDelivered;
    final statusColor = homeOrderStatusColor(order);
    final deliveryLabel = order.isCancelled
        ? 'Order cancelled'
        : order.isDelivered
            ? 'Delivered ${homeTimeAgo(order.updatedAt ?? order.createdAt)}'
            : 'Expected delivery ${homeCompactDate(expectedDate)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onProductTap,
                  child: Text(
                    order.productName.isEmpty ? 'Unknown Product' : order.productName,
                    style: TextStyle(
                        color: widget.onProductTap != null
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF0F172A),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        decoration: widget.onProductTap != null
                            ? TextDecoration.underline
                            : TextDecoration.none),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.statusLabel.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Order ${homeShortId(order.id)} • ${homeTimeAgo(order.createdAt)}',
            style: const TextStyle(
                color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'Qty ${order.quantity} • Rs ${order.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            deliveryLabel,
            style: TextStyle(
              color: order.isCancelled
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFF166534),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          HomeAnimatedDeliveryLine(order: order),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(order.addressSummary,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: widget.onTrack,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF1D4ED8),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.route_rounded, size: 17),
              label: const Text('Track Order'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onCall,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFD8E0EC)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.call_outlined, size: 17),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onMessage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFD8E0EC)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.message_outlined, size: 17),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isCancelling ? null : _cancelOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF3B30),
                  side: const BorderSide(color: Color(0xFFFF3B30)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: _isCancelling
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFFF3B30)))
                    : const Icon(Icons.cancel_outlined, size: 17),
                label: const Text('Cancel Order'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Animated delivery line ────────────────────────────────────────────────────

class HomeAnimatedDeliveryLine extends StatelessWidget {
  const HomeAnimatedDeliveryLine({super.key, required this.order});
  final HomeUserOrder order;

  static const _steps = ['Placed', 'Packed', 'Shipped', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final safeStep = order.progressStepIndex.clamp(0, _steps.length - 1);
    final progress = order.isCancelled
        ? 0.0
        : ((safeStep + 1) / _steps.length).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey('${order.id}_${order.status}_line'),
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Stack(
              children: [
                Container(
                  height: 7,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF4ADE80), Color(0xFF16A34A)]),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(_steps.length, (index) {
            final isReached = !order.isCancelled && index <= safeStep;
            return Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: order.isCancelled
                          ? const Color(0xFFB91C1C)
                          : isReached
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFCBD5E1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _steps[index],
                    style: TextStyle(
                      color: isReached
                          ? const Color(0xFF166534)
                          : const Color(0xFF94A3B8),
                      fontSize: 10.3,
                      fontWeight:
                          isReached ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
