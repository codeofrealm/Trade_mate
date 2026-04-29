import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../data/models/admin_product.dart';
import '../../data/services/admin_catalog_service.dart';
import 'admin_product_form_page.dart';

class AdminLowStockPage extends StatelessWidget {
  const AdminLowStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        automaticallyImplyLeading: false,
        title: const Text('Low Stock Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<AdminProduct>>(
        stream: AdminCatalogService.instance.streamProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final lowStock = snapshot.data!
              .where((p) => p.isActive && p.stock <= 5)
              .toList()
            ..sort((a, b) => a.stock.compareTo(b.stock));

          if (lowStock.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded,
                        color: Color(0xFF34C759), size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('All products have sufficient stock!',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF000000))),
                  const SizedBox(height: 4),
                  const Text('No low stock warnings at this time.',
                      style: TextStyle(
                          color: Color(0xFF8E8E93), fontSize: 13)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Summary banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFFF3B30).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFF3B30), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lowStock.length} product${lowStock.length > 1 ? 's' : ''} need restocking',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFFFF3B30)),
                          ),
                          const Text(
                            'Tap any product to edit and update stock.',
                            style: TextStyle(
                                color: Color(0xFF8E8E93), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Product list
              ...lowStock.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LowStockCard(
                      product: p,
                      onEdit: () => Navigator.of(context).pushNamed(
                        AppRoutes.adminProductForm,
                        arguments: AdminProductFormArgs(product: p),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.product, required this.onEdit});
  final AdminProduct product;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isOut = product.stock == 0;
    final stockColor =
        isOut ? const Color(0xFFFF3B30) : const Color(0xFFFF9500);

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOut
                ? const Color(0xFFFF3B30).withOpacity(0.3)
                : const Color(0xFFFF9500).withOpacity(0.3),
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 52, height: 52,
                color: const Color(0xFFE5E5EA),
                child: _buildImage(product),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF000000))),
                  const SizedBox(height: 2),
                  Text(product.category,
                      style: const TextStyle(
                          color: Color(0xFF8E8E93), fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: stockColor.withOpacity(
                              isOut ? 1.0 : 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOut
                              ? 'OUT OF STOCK'
                              : 'Only ${product.stock} left',
                          style: TextStyle(
                              color: isOut
                                  ? Colors.white
                                  : stockColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Rs ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Edit button
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined,
                      size: 14, color: Color(0xFF007AFF)),
                  SizedBox(width: 4),
                  Text('Edit',
                      style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(AdminProduct p) {
    final b64 = p.imageBase64?.trim() ?? '';
    final url = p.imageUrl?.trim() ?? '';
    if (b64.isNotEmpty) {
      try {
        return Image.memory(base64Decode(b64), fit: BoxFit.cover);
      } catch (_) {}
    }
    if (url.isNotEmpty) {
      return Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_outlined, color: Color(0xFF8E8E93)));
    }
    return const Icon(Icons.inventory_2_outlined,
        color: Color(0xFF8E8E93), size: 22);
  }
}
