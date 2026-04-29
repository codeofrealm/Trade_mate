import 'package:flutter/material.dart';
import 'package:trade_mate/features/admin/data/models/admin_product.dart';
import '../../../pages/admin_low_stock_page.dart';

class AdminLowStockWarning extends StatelessWidget {
  const AdminLowStockWarning(
      {super.key, required this.products, required this.onEditTap});
  final List<AdminProduct> products;
  final ValueChanged<AdminProduct> onEditTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AdminLowStockPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFF3B30), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Low Stock Warning',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFFFF3B30))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${products.length} products',
                      style: const TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...products.take(5).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => onEditTap(p),
                    child: Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: Color(0xFFFF3B30), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF000000))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.stock == 0
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFFFF9500).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.stock == 0 ? 'OUT OF STOCK' : 'Stock: ${p.stock}',
                            style: TextStyle(
                                color: p.stock == 0
                                    ? Colors.white
                                    : const Color(0xFFFF9500),
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined,
                            size: 14, color: Color(0xFFFF3B30)),
                      ],
                    ),
                  ),
                )),
            if (products.length > 5)
              Text('+${products.length - 5} more low stock products',
                  style: const TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
