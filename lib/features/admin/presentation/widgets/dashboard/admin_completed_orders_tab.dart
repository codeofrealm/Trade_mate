import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../data/models/admin_user_order.dart';
import '../../../data/services/admin_catalog_service.dart';
import '../../../utils/admin_helpers.dart';
import '../shared/admin_shared_widgets.dart';
import 'orders/admin_order_card.dart';

class AdminCompletedOrdersTab extends StatefulWidget {
  const AdminCompletedOrdersTab({super.key});

  @override
  State<AdminCompletedOrdersTab> createState() =>
      _AdminCompletedOrdersTabState();
}

class _AdminCompletedOrdersTabState extends State<AdminCompletedOrdersTab> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminUserOrder>>(
      stream: AdminCatalogService.instance.streamOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load orders.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final all = snapshot.data!;
        final allCompleted = all.where((o) {
          final s = o.status.trim().toLowerCase();
          return s == 'delivered' || s == 'cancelled' || s == 'canceled';
        }).toList();

        var filtered = List<AdminUserOrder>.from(allCompleted);
        if (_filterStatus == 'delivered') {
          filtered = filtered
              .where((o) => o.status.trim().toLowerCase() == 'delivered')
              .toList();
        } else if (_filterStatus == 'cancelled') {
          filtered = filtered.where((o) => o.isCancelled).toList();
        }
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          filtered = filtered
              .where(
                (o) =>
                    o.productName.toLowerCase().contains(q) ||
                    o.productCategory.toLowerCase().contains(q) ||
                    o.id.toLowerCase().contains(q) ||
                    o.shortUserId.toLowerCase().contains(q),
              )
              .toList();
        }

        final deliveredCount = allCompleted.where((o) => o.isDelivered).length;
        final cancelledCount = allCompleted.where((o) => o.isCancelled).length;
        final totalAmount = allCompleted
            .where((o) => o.isDelivered)
            .fold(0.0, (s, o) => s + o.totalAmount);

        return CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _CompletedHeader(
                totalCompleted: allCompleted.length,
                deliveredCount: deliveredCount,
                cancelledCount: cancelledCount,
                totalAmount: totalAmount,
                search: _search,
                filterStatus: _filterStatus,
                filteredCount: filtered.length,
                searchCtrl: _searchCtrl,
                onSearchChanged: (v) => setState(() => _search = v.trim()),
                onSearchClear: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                },
                onFilterTap: () => _showFilterSheet(context),
                onFilterClear: () => setState(() => _filterStatus = 'all'),
              ),
            ),
            filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _search.isNotEmpty || _filterStatus != 'all'
                            ? 'No orders match your filter.'
                            : 'No completed orders yet.',
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
                          child: AdminOrderCard(order: filtered[index]),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF2F2F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filter Completed Orders',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['all', 'delivered', 'cancelled'].map((s) {
                final selected = _filterStatus == s;
                final color = s == 'all'
                    ? const Color(0xFF007AFF)
                    : adminStatusColor(s);
                return GestureDetector(
                  onTap: () {
                    setState(() => _filterStatus = s);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? color : const Color(0xFFE5E5EA),
                      ),
                    ),
                    child: Text(
                      s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF3C3C43),
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedHeader extends SliverPersistentHeaderDelegate {
  const _CompletedHeader({
    required this.totalCompleted,
    required this.deliveredCount,
    required this.cancelledCount,
    required this.totalAmount,
    required this.search,
    required this.filterStatus,
    required this.filteredCount,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onFilterTap,
    required this.onFilterClear,
  });

  final int totalCompleted;
  final int deliveredCount;
  final int cancelledCount;
  final double totalAmount;
  final String search;
  final String filterStatus;
  final int filteredCount;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onFilterTap;
  final VoidCallback onFilterClear;

  double get _height => filterStatus != 'all' ? 250 : 222;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_CompletedHeader old) =>
      old.totalCompleted != totalCompleted ||
      old.deliveredCount != deliveredCount ||
      old.cancelledCount != cancelledCount ||
      old.totalAmount != totalAmount ||
      old.search != search ||
      old.filterStatus != filterStatus ||
      old.filteredCount != filteredCount;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF2F2F7),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Completed Orders',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000000),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                AdminMiniStat(
                  label: 'Total',
                  value: '$totalCompleted',
                  color: const Color(0xFF007AFF),
                ),
                AdminVertDivider(),
                AdminMiniStat(
                  label: 'Delivered',
                  value: '$deliveredCount',
                  color: const Color(0xFF34C759),
                ),
                AdminVertDivider(),
                AdminMiniStat(
                  label: 'Cancelled',
                  value: '$cancelledCount',
                  color: const Color(0xFFFF3B30),
                ),
                AdminVertDivider(),
                AdminMiniStat(
                  label: 'Revenue',
                  value: adminFormatRs(totalAmount),
                  color: const Color(0xFF5856D6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _CompletedSearchRow(
            search: search,
            filterStatus: filterStatus,
            filteredCount: filteredCount,
            searchCtrl: searchCtrl,
            onSearchChanged: onSearchChanged,
            onSearchClear: onSearchClear,
            onFilterTap: onFilterTap,
            onFilterClear: onFilterClear,
          ),
        ],
      ),
    );
  }
}

class _CompletedSearchRow extends StatelessWidget {
  const _CompletedSearchRow({
    required this.search,
    required this.filterStatus,
    required this.filteredCount,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onFilterTap,
    required this.onFilterClear,
  });

  final String search;
  final String filterStatus;
  final int filteredCount;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onFilterTap;
  final VoidCallback onFilterClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD7DEE9),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 7,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(left: 18, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField.borderless(
                        controller: searchCtrl,
                        onChanged: onSearchChanged,
                        placeholder: 'Search completed orders...',
                        padding: EdgeInsets.zero,
                        cursorColor: const Color(0xFF4B46FF),
                        placeholderStyle: const TextStyle(
                          color: Color(0xFF6F7785),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (search.isNotEmpty)
                      GestureDetector(
                        onTap: onSearchClear,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB8C0CC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.search,
                        color: Color(0xFF2F333A),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: filterStatus == 'all'
                      ? Colors.white
                      : const Color(0xFF4B46FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: filterStatus == 'all'
                        ? const Color(0xFFD7DEE9)
                        : const Color(0xFF4B46FF),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: filterStatus == 'all'
                      ? const Color(0xFF8E8E93)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (filterStatus != 'all') ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: adminStatusColor(filterStatus).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filterStatus[0].toUpperCase() + filterStatus.substring(1),
                      style: TextStyle(
                        color: adminStatusColor(filterStatus),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: onFilterClear,
                      child: Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: adminStatusColor(filterStatus),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$filteredCount orders',
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
