import 'package:flutter/material.dart';
import 'package:trade_mate/features/admin/data/models/admin_customer.dart';
import '../widgets/dashboard/customers/admin_customer_order_card.dart';
import 'package:trade_mate/features/admin/utils/admin_customer_helpers.dart';

class AdminCustomerDetailPage extends StatelessWidget {
  const AdminCustomerDetailPage({super.key, required this.customer});
  final AdminCustomer customer;

  @override
  Widget build(BuildContext context) {
    final delivered = customer.orders.where((o) => o.isDelivered).length;
    final cancelled = customer.orders.where((o) => o.isCancelled).length;
    final active = customer.orders
        .where((o) => !o.isDelivered && !o.isCancelled)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFFF2F2F7),
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                color: const Color(0xFFF2F2F7),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF007AFF).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            customer.userId.isNotEmpty
                                ? customer.userId[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer',
                                style: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer.shortUserId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: Color(0xFF000000),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customer.userId,
                                style: const TextStyle(
                                  color: Color(0xFFC7C7CC),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: Row(
                        children: [
                          _StatItem(
                            label: 'Total',
                            value: '${customer.orders.length}',
                            color: const Color(0xFF007AFF),
                          ),
                          _Divider(),
                          _StatItem(
                            label: 'Active',
                            value: '$active',
                            color: const Color(0xFFFF9500),
                          ),
                          _Divider(),
                          _StatItem(
                            label: 'Delivered',
                            value: '$delivered',
                            color: const Color(0xFF34C759),
                          ),
                          _Divider(),
                          _StatItem(
                            label: 'Cancelled',
                            value: '$cancelled',
                            color: const Color(0xFFFF3B30),
                          ),
                          _Divider(),
                          _StatItem(
                            label: 'Spent',
                            value: formatRs(customer.totalSpent),
                            color: const Color(0xFF5856D6),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: Text(
              customer.shortUserId,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Order History',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          customer.orders.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No orders yet.',
                      style: TextStyle(color: Color(0xFF8E8E93)),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AdminCustomerOrderCard(
                          order: customer.orders[index],
                        ),
                      ),
                      childCount: customer.orders.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 32, color: const Color(0xFFE5E5EA));
}
