import 'package:flutter/material.dart';

import '../../../data/models/admin_user_order.dart';
import '../../../data/services/admin_catalog_service.dart';
import '../../../utils/admin_helpers.dart';
import '../shared/admin_shared_widgets.dart';
import 'orders/admin_order_card.dart';

class AdminCompletedOrdersTab extends StatefulWidget {
  const AdminCompletedOrdersTab({super.key});

  @override
  State<AdminCompletedOrdersTab> createState() => _AdminCompletedOrdersTabState();
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
              .where((o) =>
                  o.productName.toLowerCase().contains(q) ||
                  o.productCategory.toLowerCase().contains(q) ||
                  o.id.toLowerCase().contains(q) ||
                  o.shortUserId.toLowerCase().contains(q))
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Filter Completed Orders',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['all', 'delivered', 'cancelled'].map((s) {
                final selected = _filterStatus == s;
                final color =
                    s == 'all' ? const Color(0xFF007AFF) : adminStatusColor(s);
                return GestureDetector(
                  onTap: () {
                    setState(() => _filterStatus = s);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? color : const Color(0xFFE5E5EA)),
                    ),
                    child: Text(
                      s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1),
                      style: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF3C3C43),
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13),
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

  double get _height => filterStatus != 'all' ? 242 : 214;

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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF2F2F7),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Completed Orders',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                  letterSpacing: -0.4)),
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
                AdminMiniStat(label: 'Total', value: '$totalCompleted', color: const Color(0xFF007AFF)),
                AdminVertDivider(),
                AdminMiniStat(label: 'Delivered', value: '$deliveredCount', color: const Color(0xFF34C759)),
                AdminVertDivider(),
                AdminMiniStat(label: 'Cancelled', value: '$cancelledCount', color: const Color(0xFFFF3B30)),
                AdminVertDivider(),
                AdminMiniStat(label: 'Revenue', value: adminFormatRs(totalAmount), color: const Color(0xFF5856D6)),
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
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF8E8E93), size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: onSearchChanged,
                        decoration: const InputDecoration(
                          hintText: 'Search completed orders...',
                          hintStyle: TextStyle(color: Color(0xFFC7C7CC), fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (search.isNotEmpty)
                      GestureDetector(
                        onTap: onSearchClear,
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFFC7C7CC), size: 15),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: filterStatus == 'all' ? Colors.white : const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: filterStatus == 'all'
                          ? const Color(0xFFE5E5EA)
                          : const Color(0xFF007AFF)),
                ),
                child: Icon(Icons.tune_rounded,
                    size: 18,
                    color: filterStatus == 'all'
                        ? const Color(0xFF8E8E93)
                        : Colors.white),
              ),
            ),
          ],
        ),
        if (filterStatus != 'all') ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: adminStatusColor(filterStatus).withOpacity(0.12),
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
                          fontSize: 12),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: onFilterClear,
                      child: Icon(Icons.close_rounded,
                          size: 13, color: adminStatusColor(filterStatus)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('$filteredCount orders',
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
            ],
          ),
        ],
      ],
    );
  }
}
