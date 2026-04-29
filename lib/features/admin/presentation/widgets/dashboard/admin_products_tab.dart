import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../data/models/admin_product.dart';
import '../../../data/services/admin_catalog_service.dart';

class AdminProductsTab extends StatefulWidget {
  const AdminProductsTab({
    super.key,
    required this.onUploadTap,
    required this.onEditTap,
  });

  final VoidCallback onUploadTap;
  final ValueChanged<AdminProduct> onEditTap;

  @override
  State<AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<AdminProductsTab> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  final Set<String> _busyIds = <String>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(AdminProduct product) async {
    if (_busyIds.contains(product.id)) return;
    setState(() => _busyIds.add(product.id));
    try {
      await AdminCatalogService.instance.setProductActiveStatus(
        productId: product.id,
        isActive: !product.isActive,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(product.isActive
            ? 'Product deactivated successfully.'
            : 'Product activated successfully.'),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update product status.')),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(product.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminProduct>>(
      stream: AdminCatalogService.instance.streamProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load products.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final all = snapshot.data!;

        // Mini dashboard stats
        final totalCount = all.length;
        final activeCount = all.where((p) => p.isActive).length;

        AdminProduct? minStockProduct;
        AdminProduct? maxStockProduct;
        for (final p in all) {
          if (minStockProduct == null || p.stock < minStockProduct.stock) {
            minStockProduct = p;
          }
          if (maxStockProduct == null || p.stock > maxStockProduct.stock) {
            maxStockProduct = p;
          }
        }

        // Search filter
        var filtered = all;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          filtered = all
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.category.toLowerCase().contains(q))
              .toList();
        }

        if (all.isEmpty) {
          return _EmptyProducts(onUploadTap: widget.onUploadTap);
        }

        return CustomScrollView(
          slivers: [
            // ── Sticky header ──
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeader(
                totalCount: totalCount,
                activeCount: activeCount,
                minStockProduct: minStockProduct,
                maxStockProduct: maxStockProduct,
                search: _search,
                searchCtrl: _searchCtrl,
                onSearchChanged: (v) => setState(() => _search = v.trim()),
                onSearchClear: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                },
              ),
            ),

            // ── Products list ──
            filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No products match "$_search".',
                        style: const TextStyle(color: Color(0xFF8E8E93)),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ProductCard(
                              product: product,
                              isBusy: _busyIds.contains(product.id),
                              onEditTap: () => widget.onEditTap(product),
                              onToggleTap: () => _toggleStatus(product),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

// ── Sticky header ─────────────────────────────────────────────────────────────

class _StickyHeader extends SliverPersistentHeaderDelegate {
  const _StickyHeader({
    required this.totalCount,
    required this.activeCount,
    required this.minStockProduct,
    required this.maxStockProduct,
    required this.search,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  final int totalCount;
  final int activeCount;
  final AdminProduct? minStockProduct;
  final AdminProduct? maxStockProduct;
  final String search;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;

  @override
  double get minExtent => 216;
  @override
  double get maxExtent => 216;

  @override
  bool shouldRebuild(_StickyHeader old) =>
      old.totalCount != totalCount ||
      old.activeCount != activeCount ||
      old.minStockProduct?.id != minStockProduct?.id ||
      old.maxStockProduct?.id != maxStockProduct?.id ||
      old.search != search;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF2F2F7),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Products',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                  letterSpacing: -0.4)),
          const SizedBox(height: 10),

          // ── Mini dashboard ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Column(
              children: [
                // Row 1: Total + Active
                Row(
                  children: [
                    _MiniStat(
                        label: 'Total Products',
                        value: '$totalCount',
                        color: const Color(0xFF007AFF)),
                    _VertDivider(),
                    _MiniStat(
                        label: 'Active',
                        value: '$activeCount',
                        color: const Color(0xFF34C759)),
                    _VertDivider(),
                    _MiniStat(
                        label: 'Inactive',
                        value: '${totalCount - activeCount}',
                        color: const Color(0xFFFF3B30)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFE5E5EA)),
                const SizedBox(height: 10),
                // Row 2: Min + Max stock
                Row(
                  children: [
                    Expanded(
                      child: _StockItem(
                        label: 'Min Stock',
                        product: minStockProduct,
                        color: const Color(0xFFFF3B30),
                        icon: Icons.arrow_downward_rounded,
                      ),
                    ),
                    Container(
                        width: 0.5, height: 32,
                        color: const Color(0xFFE5E5EA)),
                    Expanded(
                      child: _StockItem(
                        label: 'Max Stock',
                        product: maxStockProduct,
                        color: const Color(0xFF34C759),
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Search ──
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
                      hintText: 'Search products...',
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
                  fontSize: 10,
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

class _StockItem extends StatelessWidget {
  const _StockItem({
    required this.label,
    required this.product,
    required this.color,
    required this.icon,
  });
  final String label;
  final AdminProduct? product;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(
                  product == null
                      ? '-'
                      : '${product!.name.length > 14 ? '${product!.name.substring(0, 14)}…' : product!.name} (${product!.stock})',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isBusy,
    required this.onEditTap,
    required this.onToggleTap,
  });

  final AdminProduct product;
  final bool isBusy;
  final VoidCallback onEditTap;
  final VoidCallback onToggleTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductThumb(
                  imageUrl: product.imageUrl,
                  imageBase64: product.imageBase64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF000000))),
                    const SizedBox(height: 2),
                    Text(product.category,
                        style: const TextStyle(
                            color: Color(0xFF8E8E93), fontSize: 12.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _InfoPill(
                            icon: Icons.currency_rupee_rounded,
                            text: product.price.toStringAsFixed(0)),
                        _InfoPill(
                            icon: Icons.inventory_2_outlined,
                            text: 'Stock ${product.stock}'),
                        _InfoPill(
                            icon: Icons.sell_outlined,
                            text: 'Sold ${product.soldCount}'),
                        _InfoPill(
                            icon: Icons.star_outline_rounded,
                            text:
                                '${product.rating.toStringAsFixed(1)} (${product.reviewCount})'),
                      ],
                    ),
                  ],
                ),
              ),
              _StatusChip(isActive: product.isActive),
            ],
          ),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(product.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF8E8E93), fontSize: 12.5)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : onEditTap,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onToggleTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: product.isActive
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF34C759),
                  ),
                  icon: isBusy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(
                          product.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 16),
                  label: Text(product.isActive ? 'Deactivate' : 'Activate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF8E8E93)),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3C3C43))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF34C759).withOpacity(0.12)
            : const Color(0xFFFF3B30).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
            color: isActive
                ? const Color(0xFF34C759)
                : const Color(0xFFFF3B30),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({this.imageUrl, this.imageBase64});
  final String? imageUrl;
  final String? imageBase64;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final b64 = imageBase64?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        color: const Color(0xFFE5E5EA),
        child: b64.isNotEmpty
            ? (() {
                try {
                  return Image.memory(base64Decode(b64), fit: BoxFit.cover);
                } catch (_) {
                  return const Icon(Icons.broken_image_outlined,
                      color: Color(0xFF8E8E93));
                }
              })()
            : url.isNotEmpty
                ? Image.network(url, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF8E8E93)))
                : const Icon(Icons.image_outlined, color: Color(0xFF8E8E93)),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.onUploadTap});
  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 32, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 12),
            const Text('No products yet',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF000000))),
            const SizedBox(height: 4),
            const Text('Tap the + button to add your first product.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onUploadTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
