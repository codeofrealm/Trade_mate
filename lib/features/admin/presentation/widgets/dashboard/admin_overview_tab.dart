import 'package:flutter/material.dart';

import '../../../data/models/admin_product.dart';
import '../../../data/models/admin_user_order.dart';
import '../../../data/services/admin_catalog_service.dart';
import 'overview/admin_low_stock_warning.dart';
import 'overview/admin_overview_widgets.dart';

class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({super.key, required this.onEditTap});
  final ValueChanged<AdminProduct> onEditTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminProduct>>(
      stream: AdminCatalogService.instance.streamProducts(),
      builder: (context, productSnap) {
        return StreamBuilder<List<AdminUserOrder>>(
          stream: AdminCatalogService.instance.streamOrders(limit: 1000),
          builder: (context, orderSnap) {
            final products = productSnap.data ?? [];
            final orders = orderSnap.data ?? [];
            final now = DateTime.now();

            final lowStock = products
                .where((p) => p.isActive && p.stock <= 5)
                .toList()
              ..sort((a, b) => a.stock.compareTo(b.stock));

            final totalOrderAmount = orders
                .where((o) => !o.isCancelled)
                .fold(0.0, (s, o) => s + o.totalAmount);

            final deliveredAmount = orders
                .where((o) => o.isDelivered)
                .fold(0.0, (s, o) => s + o.totalAmount);

            double _periodAmount(bool Function(AdminUserOrder) test) =>
                orders.where((o) => !o.isCancelled && test(o))
                    .fold(0.0, (s, o) => s + o.totalAmount);

            final weekStart = now.subtract(Duration(days: now.weekday - 1));

            final Map<int, double> monthlyMap = {};
            final Map<int, double> weeklyMap = {};
            final Map<int, double> dailyMap = {};

            for (var i = 6; i >= 0; i--) {
              final day = now.subtract(Duration(days: i));
              weeklyMap[6 - i] = orders
                  .where((o) =>
                      !o.isCancelled &&
                      o.createdAt != null &&
                      o.createdAt!.year == day.year &&
                      o.createdAt!.month == day.month &&
                      o.createdAt!.day == day.day)
                  .fold(0.0, (s, o) => s + o.totalAmount);
            }
            for (var i = 29; i >= 0; i--) {
              final day = now.subtract(Duration(days: i));
              dailyMap[29 - i] = orders
                  .where((o) =>
                      !o.isCancelled &&
                      o.createdAt != null &&
                      o.createdAt!.year == day.year &&
                      o.createdAt!.month == day.month &&
                      o.createdAt!.day == day.day)
                  .fold(0.0, (s, o) => s + o.totalAmount);
            }
            for (final o in orders) {
              if (o.isCancelled || o.createdAt == null) continue;
              if (o.createdAt!.year != now.year) continue;
              monthlyMap[o.createdAt!.month] =
                  (monthlyMap[o.createdAt!.month] ?? 0) + o.totalAmount;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (lowStock.isNotEmpty) ...[
                  AdminLowStockWarning(products: lowStock, onEditTap: onEditTap),
                  const SizedBox(height: 16),
                ],
                const _SectionTitle(text: 'Overview'),
                const SizedBox(height: 10),
                AdminStatsGrid(
                  totalProducts: products.length,
                  totalUsers: orders.map((o) => o.userId).toSet().length,
                  totalOrders: orders.length,
                  activeOrders: orders.where((o) {
                    final s = o.status.trim().toLowerCase();
                    return s != 'delivered' && s != 'cancelled' && s != 'canceled';
                  }).length,
                  deliveredAmount: deliveredAmount,
                  totalOrderAmount: totalOrderAmount,
                ),
                const SizedBox(height: 20),
                const _SectionTitle(text: 'Revenue Summary'),
                const SizedBox(height: 10),
                AdminProfitRow(
                  today: _periodAmount((o) =>
                      o.createdAt != null &&
                      o.createdAt!.year == now.year &&
                      o.createdAt!.month == now.month &&
                      o.createdAt!.day == now.day),
                  weekly: _periodAmount((o) =>
                      o.createdAt != null &&
                      !o.createdAt!.isBefore(DateTime(
                          weekStart.year, weekStart.month, weekStart.day))),
                  monthly: _periodAmount((o) =>
                      o.createdAt != null &&
                      o.createdAt!.year == now.year &&
                      o.createdAt!.month == now.month),
                  yearly: _periodAmount((o) =>
                      o.createdAt != null && o.createdAt!.year == now.year),
                ),
                const SizedBox(height: 20),
                const _SectionTitle(text: 'Revenue Charts'),
                const SizedBox(height: 10),
                AdminChartCard(
                  title: 'Last 7 Days',
                  subtitle: 'Daily revenue this week',
                  dataMap: weeklyMap,
                  barCount: 7,
                  color: const Color(0xFF007AFF),
                  labelBuilder: (i) {
                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    return days[now.subtract(Duration(days: 6 - i)).weekday - 1];
                  },
                ),
                const SizedBox(height: 12),
                AdminChartCard(
                  title: 'This Month (Daily)',
                  subtitle: 'Last 30 days revenue',
                  dataMap: dailyMap,
                  barCount: 30,
                  color: const Color(0xFF34C759),
                  labelBuilder: (i) =>
                      '${now.subtract(Duration(days: 29 - i)).day}',
                ),
                const SizedBox(height: 12),
                AdminChartCard(
                  title: 'This Year (Monthly)',
                  subtitle: 'Monthly revenue ${now.year}',
                  dataMap: monthlyMap,
                  barCount: 12,
                  color: const Color(0xFF5856D6),
                  labelBuilder: (i) {
                    const m = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                    return m[i];
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF000000),
          letterSpacing: -0.3));
}
