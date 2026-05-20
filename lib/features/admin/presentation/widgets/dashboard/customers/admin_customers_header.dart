import 'package:flutter/cupertino.dart';
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
  double get minExtent => 180;
  @override
  double get maxExtent => 180;

  @override
  bool shouldRebuild(AdminCustomersHeader old) =>
      old.customerCount != customerCount ||
      old.totalAmount != totalAmount ||
      old.search != search;

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
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD7DEE9), width: 1.2),
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
                    placeholder: 'Search by user ID...',
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
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
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

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 28, color: const Color(0xFFE5E5EA));
}
