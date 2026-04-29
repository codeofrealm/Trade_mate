import 'package:flutter/material.dart';
import 'package:trade_mate/features/admin/utils/admin_customer_helpers.dart';

class AdminCustomersHeader extends SliverPersistentHeaderDelegate {
  const AdminCustomersHeader({
    required this.customerCount,
    required this.totalAmount,
    required this.search,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  final int customerCount;
  final double totalAmount;
  final String search;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;

  @override
  double get minExtent => 172;
  @override
  double get maxExtent => 172;

  @override
  bool shouldRebuild(AdminCustomersHeader old) =>
      old.customerCount != customerCount ||
      old.totalAmount != totalAmount ||
      old.search != search;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF2F2F7),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customers',
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
                _MiniStat(
                  label: 'Customers',
                  value: '$customerCount',
                  color: const Color(0xFF007AFF),
                ),
                _VertDivider(),
                _MiniStat(
                  label: 'Total Spent',
                  value: formatRs(totalAmount),
                  color: const Color(0xFF34C759),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
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
                      hintText: 'Search by user ID...',
                      hintStyle:
                          TextStyle(color: Color(0xFFC7C7CC), fontSize: 13),
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
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 28, color: const Color(0xFFE5E5EA));
}
