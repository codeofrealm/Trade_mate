import 'package:flutter/material.dart';

import '../../../data/models/admin_customer.dart';
import '../../../data/models/admin_user_order.dart';
import '../../../data/services/admin_catalog_service.dart';
import '../../pages/admin_customer_detail_page.dart';
import 'customers/admin_customer_card.dart';
import 'customers/admin_customers_header.dart';

class AdminReviewsTab extends StatefulWidget {
  const AdminReviewsTab({super.key});

  @override
  State<AdminReviewsTab> createState() => _AdminReviewsTabState();
}

class _AdminReviewsTabState extends State<AdminReviewsTab> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Map<String, AdminCustomer> _buildCustomerMap(List<AdminUserOrder> orders) {
    final map = <String, AdminCustomer>{};
    for (final o in orders) {
      if (o.userId.isEmpty) continue;
      if (map.containsKey(o.userId)) {
        map[o.userId]!.orders.add(o);
        map[o.userId]!.totalSpent += o.isCancelled ? 0 : o.totalAmount;
      } else {
        map[o.userId] = AdminCustomer(
          userId: o.userId,
          orders: [o],
          totalSpent: o.isCancelled ? 0 : o.totalAmount,
        );
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminUserOrder>>(
      stream: AdminCatalogService.instance.streamOrders(limit: 1000),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load customers.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final customerMap = _buildCustomerMap(snapshot.data!);

        var customers = customerMap.values.toList()
          ..sort((a, b) => b.orders.length.compareTo(a.orders.length));

        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          customers =
              customers.where((c) => c.userId.toLowerCase().contains(q)).toList();
        }

        final totalAmount =
            customerMap.values.fold(0.0, (s, c) => s + c.totalSpent);

        return CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: AdminCustomersHeader(
                customerCount: customerMap.length,
                totalAmount: totalAmount,
                search: _search,
                searchCtrl: _searchCtrl,
                onSearchChanged: (v) => setState(() => _search = v.trim()),
                onSearchClear: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                },
              ),
            ),
            customers.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _search.isNotEmpty
                            ? 'No customers match your search.'
                            : 'No customers yet.',
                        style: const TextStyle(color: Color(0xFF8E8E93)),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AdminCustomerCard(
                            customer: customers[index],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AdminCustomerDetailPage(
                                    customer: customers[index]),
                              ),
                            ),
                          ),
                        ),
                        childCount: customers.length,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}
