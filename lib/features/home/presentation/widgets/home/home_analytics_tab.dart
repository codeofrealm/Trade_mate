import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:trade_mate/features/home/utils/home_helpers.dart';
import '../analytics/home_analytics_widgets.dart';

class HomeAnalyticsTab extends StatelessWidget {
  const HomeAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please login to view analytics.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final orders = snap.data!.docs
            .map((d) => HomeOrderStat.fromDoc(d.id, d.data()))
            .toList()
          ..sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

        final active = orders.where((o) => !o.isCancelled).toList();
        final now = DateTime.now();

        double _sum(bool Function(HomeOrderStat) test) =>
            active.where(test).fold(0.0, (s, o) => s + o.amount);

        final monthlyMap = <int, double>{};
        for (final o in active) {
          if (o.createdAt != null && o.createdAt!.year == now.year) {
            monthlyMap[o.createdAt!.month] =
                (monthlyMap[o.createdAt!.month] ?? 0) + o.amount;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Analytics',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                      letterSpacing: -0.5,
                      height: 1.1)),
              const SizedBox(height: 2),
              const Text('Your spending summary',
                  style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                      fontWeight: FontWeight.w400)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: HomeAnalyticsStatCard(
                      label: 'Today',
                      amount: _sum((o) =>
                          o.createdAt != null &&
                          o.createdAt!.year == now.year &&
                          o.createdAt!.month == now.month &&
                          o.createdAt!.day == now.day),
                      icon: Icons.wb_sunny_outlined,
                      color: const Color(0xFFFF9500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HomeAnalyticsStatCard(
                      label: 'This Month',
                      amount: _sum((o) =>
                          o.createdAt != null &&
                          o.createdAt!.year == now.year &&
                          o.createdAt!.month == now.month),
                      icon: Icons.calendar_month_outlined,
                      color: const Color(0xFF007AFF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: HomeAnalyticsStatCard(
                      label: 'This Year',
                      amount: _sum((o) =>
                          o.createdAt != null && o.createdAt!.year == now.year),
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFF5856D6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HomeAnalyticsStatCard(
                      label: 'All Time',
                      amount: active.fold(0.0, (s, o) => s + o.amount),
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF34C759),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Row(
                  children: [
                    HomeCountItem(label: 'Total', value: orders.length, color: const Color(0xFF007AFF)),
                    HomeCountDivider(),
                    HomeCountItem(
                        label: 'Active',
                        value: orders.where((o) => !o.isDelivered && !o.isCancelled).length,
                        color: const Color(0xFFFF9500)),
                    HomeCountDivider(),
                    HomeCountItem(
                        label: 'Delivered',
                        value: orders.where((o) => o.isDelivered).length,
                        color: const Color(0xFF34C759)),
                    HomeCountDivider(),
                    HomeCountItem(
                        label: 'Cancelled',
                        value: orders.where((o) => o.isCancelled).length,
                        color: const Color(0xFFFF3B30)),
                  ],
                ),
              ),
              if (monthlyMap.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Monthly Spending',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                        letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text('${now.year}',
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                const SizedBox(height: 12),
                HomeMonthlyChart(monthlyMap: monthlyMap, now: now),
              ],
              const SizedBox(height: 20),
              const Text('Order History',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                      letterSpacing: -0.3)),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: const Center(
                    child: Text('No orders yet.',
                        style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
                  ),
                )
              else
                ...orders.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HomeOrderHistoryCard(order: o),
                    )),
            ],
          ),
        );
      },
    );
  }
}
