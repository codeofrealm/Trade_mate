import 'package:flutter/material.dart';
import 'package:trade_mate/features/admin/utils/admin_helpers.dart';

// ── Stats grid ────────────────────────────────────────────────────────────────

class AdminStatsGrid extends StatelessWidget {
  const AdminStatsGrid({
    super.key,
    required this.totalProducts,
    required this.totalUsers,
    required this.totalOrders,
    required this.deliveredAmount,
    required this.totalOrderAmount,
  });

  final int totalProducts;
  final int totalUsers;
  final int totalOrders;
  final double deliveredAmount;
  final double totalOrderAmount;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatData('Total Products', '$totalProducts',
          Icons.inventory_2_outlined, const Color(0xFF007AFF)),
      _StatData('Total Users', '$totalUsers',
          Icons.people_outline_rounded, const Color(0xFF5856D6)),
      _StatData('Total Orders', '$totalOrders',
          Icons.receipt_long_outlined, const Color(0xFFFF9500)),
      _StatData('Delivered Revenue', adminFormatRs(deliveredAmount),
          Icons.check_circle_outline_rounded, const Color(0xFF34C759)),
      _StatData('Total Order Amount', adminFormatRs(totalOrderAmount),
          Icons.currency_rupee_rounded, const Color(0xFFFF3B30)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _StatCard(data: items[i]),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 17),
          ),
          const Spacer(),
          Text(data.label,
              style: const TextStyle(
                  color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(data.value,
              style: TextStyle(
                  color: data.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4)),
        ],
      ),
    );
  }
}

// ── Profit row ────────────────────────────────────────────────────────────────

class AdminProfitRow extends StatelessWidget {
  const AdminProfitRow({
    super.key,
    required this.today,
    required this.weekly,
    required this.monthly,
    required this.yearly,
  });

  final double today;
  final double weekly;
  final double monthly;
  final double yearly;

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
        children: [
          Row(
            children: [
              _ProfitItem(label: 'Today', value: today, color: const Color(0xFF007AFF)),
              _ProfitDivider(),
              _ProfitItem(label: 'This Week', value: weekly, color: const Color(0xFF34C759)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 12),
          Row(
            children: [
              _ProfitItem(label: 'This Month', value: monthly, color: const Color(0xFF5856D6)),
              _ProfitDivider(),
              _ProfitItem(label: 'This Year', value: yearly, color: const Color(0xFFFF9500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfitItem extends StatelessWidget {
  const _ProfitItem({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(adminFormatRs(value),
              style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4)),
        ],
      ),
    );
  }
}

class _ProfitDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 36, color: const Color(0xFFE5E5EA));
}

// ── Chart card ────────────────────────────────────────────────────────────────

class AdminChartCard extends StatelessWidget {
  const AdminChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dataMap,
    required this.barCount,
    required this.color,
    required this.labelBuilder,
  });

  final String title;
  final String subtitle;
  final Map<int, double> dataMap;
  final int barCount;
  final Color color;
  final String Function(int) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final maxVal = dataMap.values.isEmpty
        ? 1.0
        : dataMap.values.reduce((a, b) => a > b ? a : b);
    final total = dataMap.values.fold(0.0, (s, v) => s + v);

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF000000))),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFF8E8E93), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(adminFormatRs(total),
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(barCount, (i) {
                final val = dataMap[i] ?? 0.0;
                final ratio = maxVal > 0 ? val / maxVal : 0.0;
                final isToday = i == barCount - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          height: (ratio * 64).clamp(2.0, 64.0),
                          decoration: BoxDecoration(
                            color: isToday ? color : color.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(barCount, (i) {
              final showLabel = barCount <= 12 ||
                  i == 0 ||
                  i == barCount - 1 ||
                  i % (barCount ~/ 6) == 0;
              return Expanded(
                child: Text(
                  showLabel ? labelBuilder(i) : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: barCount > 12 ? 7 : 9,
                    color: i == barCount - 1 ? color : const Color(0xFFC7C7CC),
                    fontWeight: i == barCount - 1
                        ? FontWeight.w700
                        : FontWeight.w400,
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
