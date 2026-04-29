import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../data/models/admin_user_order.dart';
import '../../../data/services/admin_catalog_service.dart';
import '../../../utils/admin_helpers.dart';
import '../shared/admin_shared_widgets.dart';
import 'orders/admin_order_card.dart';

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filterStatus = 'all';

  static const _statuses = ['all', 'placed', 'processing', 'packed', 'shipped'];

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
        var filtered = all.where((o) {
          final s = o.status.trim().toLowerCase();
          return s != 'delivered' && s != 'cancelled' && s != 'canceled';
        }).toList();

        if (_filterStatus != 'all') {
          filtered = filtered
              .where((o) => o.status.trim().toLowerCase() == _filterStatus)
              .toList();
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

        final counts = {
          'active': all.where((o) {
            final s = o.status.trim().toLowerCase();
            return s != 'delivered' && s != 'cancelled' && s != 'canceled';
          }).length,
          'placed': all
              .where((o) => o.status.trim().toLowerCase() == 'placed')
              .length,
          'processing': all
              .where((o) => o.status.trim().toLowerCase() == 'processing')
              .length,
          'packed': all
              .where((o) => o.status.trim().toLowerCase() == 'packed')
              .length,
          'shipped': all
              .where((o) => o.status.trim().toLowerCase() == 'shipped')
              .length,
        };

        return CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _OrdersHeader(
                counts: counts,
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
                            : 'No active orders.',
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
                          child: AdminOrderCard(
                            order: filtered[index],
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  AdminOrderDetailSheet(order: filtered[index]),
                            ),
                          ),
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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filter by Status',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((s) {
                final selected = _filterStatus == s;
                final color = s == 'all' ? const Color(0xFF007AFF) : adminStatusColor(s);
                return GestureDetector(
                  onTap: () {
                    setState(() => _filterStatus = s);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected ? color : const Color(0xFFE5E5EA),
                        width: selected ? 0 : 1,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Text(
                      s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1),
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF3C3C43),
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: -0.2,
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

class _OrdersHeader extends SliverPersistentHeaderDelegate {
  const _OrdersHeader({
    required this.counts,
    required this.search,
    required this.filterStatus,
    required this.filteredCount,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onFilterTap,
    required this.onFilterClear,
  });

  final Map<String, int> counts;
  final String search;
  final String filterStatus;
  final int filteredCount;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onFilterTap;
  final VoidCallback onFilterClear;

  double get _height => filterStatus != 'all' ? 278 : 250;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(_OrdersHeader old) =>
      old.counts.toString() != counts.toString() ||
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Orders',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000000),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      AdminMiniStat(label: 'Total', value: '${counts['active']}', color: const Color(0xFF007AFF), fontSize: 20),
                      AdminVertDivider(height: 36),
                      AdminMiniStat(label: 'Placed', value: '${counts['placed']}', color: const Color(0xFF5856D6), fontSize: 20),
                      AdminVertDivider(height: 36),
                      AdminMiniStat(label: 'Processing', value: '${counts['processing']}', color: const Color(0xFFFF9500), fontSize: 20),
                    ],
                  ),
                ),
                Container(height: 0.5, color: const Color(0xFFE5E5EA), margin: const EdgeInsets.symmetric(horizontal: 16)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      AdminMiniStat(label: 'Packed', value: '${counts['packed']}', color: const Color(0xFFFF9500), fontSize: 20),
                      AdminVertDivider(height: 36),
                      AdminMiniStat(label: 'Shipped', value: '${counts['shipped']}', color: const Color(0xFF34C759), fontSize: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SearchFilterRow(
            search: search,
            filterStatus: filterStatus,
            filteredCount: filteredCount,
            searchCtrl: searchCtrl,
            onSearchChanged: onSearchChanged,
            onSearchClear: onSearchClear,
            onFilterTap: onFilterTap,
            onFilterClear: onFilterClear,
            hintText: 'Search orders...',
          ),
        ],
      ),
    );
  }
}

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({
    required this.search,
    required this.filterStatus,
    required this.filteredCount,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onFilterTap,
    required this.onFilterClear,
    required this.hintText,
  });

  final String search;
  final String filterStatus;
  final int filteredCount;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final VoidCallback onFilterTap;
  final VoidCallback onFilterClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.search, color: Color(0xFF8E8E93), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: hintText,
                          hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
                      ),
                    ),
                    if (search.isNotEmpty)
                      GestureDetector(
                        onTap: onSearchClear,
                        child: const Icon(CupertinoIcons.clear_circled_solid, color: Color(0xFFAEAEB2), size: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: filterStatus == 'all' ? const Color(0xFFE9E9EB) : const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.slider_horizontal_3,
                  size: 17,
                  color: filterStatus == 'all' ? const Color(0xFF3C3C43) : Colors.white,
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
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: onFilterClear,
                      child: Icon(CupertinoIcons.xmark_circle_fill, size: 13, color: adminStatusColor(filterStatus)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$filteredCount orders',
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, letterSpacing: -0.2),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
