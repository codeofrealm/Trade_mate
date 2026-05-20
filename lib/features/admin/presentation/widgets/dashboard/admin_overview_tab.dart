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
            final productCostById = {
              for (final product in products) product.id: product.costPrice,
            };
            final financeTotals = _calculateFinanceTotals(
              orders: orders,
              productCostById: productCostById,
            );

            final lowStock =
                products.where((p) => p.isActive && p.stock <= 5).toList()
                  ..sort((a, b) => a.stock.compareTo(b.stock));

            final Map<int, double> monthlyMap = {};
            final Map<int, double> weeklyMap = {};
            final Map<int, double> dailyMap = {};

            for (var i = 6; i >= 0; i--) {
              final day = now.subtract(Duration(days: i));
              weeklyMap[6 - i] = orders
                  .where(
                    (o) =>
                        !o.isCancelled &&
                        o.createdAt != null &&
                        o.createdAt!.year == day.year &&
                        o.createdAt!.month == day.month &&
                        o.createdAt!.day == day.day,
                  )
                  .fold(0.0, (s, o) => s + _orderTotal(o));
            }
            for (var i = 29; i >= 0; i--) {
              final day = now.subtract(Duration(days: i));
              dailyMap[29 - i] = orders
                  .where(
                    (o) =>
                        !o.isCancelled &&
                        o.createdAt != null &&
                        o.createdAt!.year == day.year &&
                        o.createdAt!.month == day.month &&
                        o.createdAt!.day == day.day,
                  )
                  .fold(0.0, (s, o) => s + _orderTotal(o));
            }
            for (final o in orders) {
              if (o.isCancelled || o.createdAt == null) continue;
              if (o.createdAt!.year != now.year) continue;
              monthlyMap[o.createdAt!.month] =
                  (monthlyMap[o.createdAt!.month] ?? 0) + _orderTotal(o);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (lowStock.isNotEmpty) ...[
                  AdminLowStockWarning(
                    products: lowStock,
                    onEditTap: onEditTap,
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 10),
                AdminStatsGrid(
                  totalProducts: products.length,
                  totalUsers: orders.map((o) => o.userId).toSet().length,
                  totalOrders: orders.length,
                  activeOrders: orders.where((o) {
                    final s = o.status.trim().toLowerCase();
                    return s != 'delivered' &&
                        s != 'cancelled' &&
                        s != 'canceled';
                  }).length,
                  deliveredAmount: financeTotals.deliveredAmount,
                  totalOrderAmount: financeTotals.totalAmount,
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
                    const days = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    return days[now.subtract(Duration(days: 6 - i)).weekday -
                        1];
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
                    const m = [
                      'J',
                      'F',
                      'M',
                      'A',
                      'M',
                      'J',
                      'J',
                      'A',
                      'S',
                      'O',
                      'N',
                      'D',
                    ];
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
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: Color(0xFF000000),
      letterSpacing: -0.3,
    ),
  );
}

class _FinanceTotals {
  const _FinanceTotals({
    required this.totalAmount,
    required this.deliveredAmount,
    required this.totalProfit,
    required this.totalLoss,
  });

  final double totalAmount;
  final double deliveredAmount;
  final double totalProfit;
  final double totalLoss;
}

_FinanceTotals _calculateFinanceTotals({
  required List<AdminUserOrder> orders,
  required Map<String, double> productCostById,
}) {
  double totalAmount = 0;
  double deliveredAmount = 0;
  double totalProfit = 0;
  double totalLoss = 0;

  for (final order in orders) {
    if (order.isCancelled) {
      continue;
    }

    final orderTotal = _orderTotal(order);
    totalAmount += orderTotal;
    if (order.isDelivered) {
      deliveredAmount += orderTotal;
    }

    if (order.profitAmount > 0 || order.lossAmount > 0) {
      totalProfit += order.profitAmount;
      totalLoss += order.lossAmount;
      continue;
    }

    final costPrice = order.productCostPrice > 0
        ? order.productCostPrice
        : productCostById[order.productId] ?? 0;
    if (costPrice <= 0 || order.quantity <= 0) {
      continue;
    }

    final salePrice = order.productPrice > 0
        ? order.productPrice
        : orderTotal / order.quantity;
    final margin = (salePrice - costPrice) * order.quantity;
    if (margin >= 0) {
      totalProfit += margin;
    } else {
      totalLoss += -margin;
    }
  }

  return _FinanceTotals(
    totalAmount: totalAmount,
    deliveredAmount: deliveredAmount,
    totalProfit: totalProfit,
    totalLoss: totalLoss,
  );
}

double _orderTotal(AdminUserOrder order) {
  if (order.totalAmount > 0) {
    return order.totalAmount;
  }
  if (order.quantity <= 0) {
    return 0;
  }
  return order.productPrice * order.quantity;
}
