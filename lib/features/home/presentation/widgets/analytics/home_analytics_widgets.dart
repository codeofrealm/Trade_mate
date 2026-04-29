import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trade_mate/features/home/utils/home_helpers.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class HomeOrderStat {
  const HomeOrderStat({
    required this.id,
    required this.productName,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String productName;
  final double amount;
  final String status;
  final DateTime? createdAt;

  bool get isCancelled =>
      status.trim().toLowerCase() == 'cancelled' ||
      status.trim().toLowerCase() == 'canceled';

  bool get isDelivered => status.trim().toLowerCase() == 'delivered';

  factory HomeOrderStat.fromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return HomeOrderStat(
      id: id,
      productName: (data['productName'] ?? '').toString(),
      amount: (data['totalAmount'] is num)
          ? (data['totalAmount'] as num).toDouble()
          : 0.0,
      status: (data['status'] ?? '').toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class HomeAnalyticsStatCard extends StatelessWidget {
  const HomeAnalyticsStatCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(homeFormatRs(amount),
              style: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4)),
        ],
      ),
    );
  }
}

// ── Count item ────────────────────────────────────────────────────────────────

class HomeCountItem extends StatelessWidget {
  const HomeCountItem(
      {super.key, required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class HomeCountDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 32, color: const Color(0xFFE5E5EA));
}

// ── Monthly chart ─────────────────────────────────────────────────────────────

class HomeMonthlyChart extends StatelessWidget {
  const HomeMonthlyChart(
      {super.key, required this.monthlyMap, required this.now});
  final Map<int, double> monthlyMap;
  final DateTime now;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final maxVal = monthlyMap.values.isEmpty
        ? 1.0
        : monthlyMap.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) {
                final month = i + 1;
                final val = monthlyMap[month] ?? 0.0;
                final ratio = maxVal > 0 ? val / maxVal : 0.0;
                final isCurrent = month == now.month;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            homeCompactAmount(val),
                            style: TextStyle(
                              fontSize: 7,
                              color: isCurrent
                                  ? const Color(0xFF007AFF)
                                  : const Color(0xFF8E8E93),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: ratio * 72,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF007AFF)
                                : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(12, (i) {
              final isCurrent = (i + 1) == now.month;
              return Expanded(
                child: Text(
                  _months[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    color: isCurrent
                        ? const Color(0xFF007AFF)
                        : const Color(0xFFC7C7CC),
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Order history card ────────────────────────────────────────────────────────

class HomeOrderHistoryCard extends StatelessWidget {
  const HomeOrderHistoryCard({super.key, required this.order});
  final HomeOrderStat order;

  @override
  Widget build(BuildContext context) {
    final statusColor = homeAnalyticsStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName.isEmpty ? 'Order' : order.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF000000)),
                ),
                const SizedBox(height: 3),
                Text(homeFormatDate(order.createdAt),
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(homeFormatRs(order.amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF000000),
                      letterSpacing: -0.3)),
              const SizedBox(height: 4),
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
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
