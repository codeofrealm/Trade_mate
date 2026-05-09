import 'package:flutter/material.dart';

import '../../../data/models/home_user_order.dart';
import 'package:trade_mate/features/home/utils/home_helpers.dart';

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
          const _SummaryDivider(),
          _SummaryItem(label: 'Active', value: '$active'),
          const _SummaryDivider(),
          _SummaryItem(label: 'Delivered', value: '$delivered'),
          const _SummaryDivider(),
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: const Color(0x33475569));
}

class HomeNotifBanner {
  const HomeNotifBanner({
    required this.id,
    required this.message,
    required this.color,
  });

  final String id;
  final String message;
  final Color color;
}

class HomeBannerCard extends StatelessWidget {
  const HomeBannerCard({
    super.key,
    required this.banner,
    required this.onDismiss,
  });

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
            child: Text(
              banner.message,
              style: TextStyle(
                color: banner.color,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
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

class HomeOrderTrackingCard extends StatelessWidget {
  const HomeOrderTrackingCard({
    super.key,
    required this.order,
    required this.onTrack,
    this.onProductTap,
  });

  final HomeUserOrder order;
  final VoidCallback onTrack;
  final VoidCallback? onProductTap;

  @override
  Widget build(BuildContext context) {
    final expectedDate = (order.createdAt ?? DateTime.now()).add(
      const Duration(days: 2),
    );
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
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onProductTap,
                  child: Text(
                    order.productName.isEmpty
                        ? 'Unknown Product'
                        : order.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onProductTap != null
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF0F172A),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      decoration: onProductTap != null
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onTrack,
                tooltip: 'Track order',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.route_rounded,
                  color: Color(0xFF007AFF),
                  size: 21,
                ),
              ),
              const SizedBox(width: 2),
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
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Order ${homeShortId(order.id)} - ${homeTimeAgo(order.createdAt)}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Qty ${order.quantity} - Rs ${order.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
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
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.addressSummary,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
                        colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                      ),
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
                      fontWeight: isReached ? FontWeight.w700 : FontWeight.w600,
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
