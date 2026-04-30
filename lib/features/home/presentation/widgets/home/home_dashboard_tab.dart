import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../app/app_routes.dart';
import '../../../../admin/data/models/admin_product.dart';
import '../../../data/home_product_service.dart';
import '../../pages/order_confirm_page.dart';
import '../../pages/product_details_page.dart';

class HomeDashboardTab extends StatefulWidget {
  const HomeDashboardTab(
      {super.key, required this.name, required this.onOrdersTap});

  final String name;
  final VoidCallback onOrdersTap;

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // ── Pinned top bar + title + search ──
        SliverPersistentHeader(
          pinned: true,
          delegate: _HeaderDelegate(
            name: widget.name,
            searchCtrl: _searchCtrl,
            onSearchChanged: (v) => setState(() => _search = v.trim()),
            onSearchClear: () {
              _searchCtrl.clear();
              setState(() => _search = '');
            },
          ),
        ),

        // ── Low stock section ──
        SliverToBoxAdapter(child: _LowStockSection()),

        // ── Active products label ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Text(
                  'Active Products',
                  style: TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  'See All',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Products grid ──
        _ProductsSliver(search: _search),

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

// ── Header delegate ───────────────────────────────────────────────────────────

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeaderDelegate({
    required this.name,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  final String name;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;

  static const double _h = 158;

  @override
  double get minExtent => _h;
  @override
  double get maxExtent => _h;

  @override
  bool shouldRebuild(_HeaderDelegate old) => old.name != name;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF2F2F7),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top bar
          Row(
            children: [
              // avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _NavIconBtn(
                icon: CupertinoIcons.bell,
                hasDot: true,
                onTap: (ctx) =>
                    Navigator.of(ctx).pushNamed(AppRoutes.homeNotifications),
              ),
              const SizedBox(width: 8),
              _NavIconBtn(
                icon: CupertinoIcons.person,
                onTap: (ctx) =>
                    Navigator.of(ctx).pushNamed(AppRoutes.homeProfile),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // title
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000000),
              letterSpacing: -0.6,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          // search
          _SearchBar(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            onClear: onSearchClear,
          ),
        ],
      ),
    );
  }
}

// ── Nav icon button ───────────────────────────────────────────────────────────

class _NavIconBtn extends StatelessWidget {
  const _NavIconBtn({required this.icon, this.hasDot = false, required this.onTap});

  final IconData icon;
  final bool hasDot;
  final void Function(BuildContext) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: const Color(0xFF3C3C43), size: 18),
            if (hasDot)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search,
              color: Color(0xFFAEAEB2), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(
                    color: Color(0xFFAEAEB2),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w400),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, val, __) => val.text.isNotEmpty
                ? GestureDetector(
                    onTap: onClear,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFAEAEB2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Low stock section ─────────────────────────────────────────────────────────

class _LowStockSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminProduct>>(
      stream: HomeProductService.instance.streamVisibleProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final low =
            snapshot.data!.where((p) => p.stock <= 5 && p.stock > 0).toList();
        if (low.isEmpty) return const SizedBox.shrink();

        final screenW = MediaQuery.of(context).size.width;
        // each card = ~80% of screen, so next card peeks
        final cardW = screenW * 0.80;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.flame_fill,
                      size: 13, color: Color(0xFFFF3B30)),
                  const SizedBox(width: 5),
                  const Text(
                    'Low Stock — Grab it fast!',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${low.length} item${low.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            // horizontal scroll
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: low.length,
                itemBuilder: (context, i) => Padding(
                  padding: EdgeInsets.only(
                      right: i < low.length - 1 ? 12 : 0),
                  child: SizedBox(
                    width: cardW,
                    child: _LowStockCard(product: low[i]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.product});
  final AdminProduct product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.productDetails,
        arguments: ProductDetailsPageArgs(product: product),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 10,
                offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: Container(
                width: 90,
                color: const Color(0xFFF2F2F7),
                child: _ProductImage(
                    imageUrl: product.imageUrl,
                    imageBase64: product.imageBase64),
              ),
            ),
            // info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Only ${product.stock} left!',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF000000),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(CupertinoIcons.chevron_right,
                  size: 14, color: Color(0xFFC7C7CC)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Products sliver ───────────────────────────────────────────────────────────

class _ProductsSliver extends StatelessWidget {
  const _ProductsSliver({required this.search});
  final String search;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminProduct>>(
      stream: HomeProductService.instance.streamVisibleProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _StateCard(
                icon: CupertinoIcons.wifi_slash,
                message: 'Unable to load products.',
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          );
        }
        var products = snapshot.data!;
        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          products = products
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.category.toLowerCase().contains(q))
              .toList();
        }
        if (products.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _StateCard(
                icon: CupertinoIcons.bag,
                message: search.isNotEmpty
                    ? 'No products match "$search".'
                    : 'No active products available.',
              ),
            ),
          );
        }
        final list = products.take(8).toList();
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ProductCard(
                product: list[index],
              ),
              childCount: list.length,
            ),
          ),
        );
      },
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatefulWidget {
  const _ProductCard({required this.product});
  final AdminProduct product;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {

  Future<void> _quickOrder() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.orderConfirm,
      arguments: OrderConfirmPageArgs(
        product: widget.product,
        quantity: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.productDetails,
        arguments: ProductDetailsPageArgs(product: product),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      color: const Color(0xFFF2F2F7),
                      width: double.infinity,
                      child: _ProductImage(
                        imageUrl: product.imageUrl,
                        imageBase64: product.imageBase64,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (product.stock <= 5 && product.stock > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${product.stock} left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _StarRow(rating: product.rating),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rs ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF000000),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _quickOrder,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                                  CupertinoIcons.cart_fill_badge_plus,
                                  size: 14,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Star row ──────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final stars = rating.clamp(0.0, 5.0);
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < stars.floor()) {
            return const Icon(CupertinoIcons.star_fill,
                size: 10, color: Color(0xFFFF9500));
          } else if (i < stars) {
            return const Icon(CupertinoIcons.star_lefthalf_fill,
                size: 10, color: Color(0xFFFF9500));
          }
          return const Icon(CupertinoIcons.star,
              size: 10, color: Color(0xFFD1D1D6));
        }),
        const SizedBox(width: 4),
        Text(
          stars.toStringAsFixed(1),
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Product image ─────────────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageUrl, this.imageBase64});

  final String? imageUrl;
  final String? imageBase64;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final b64 = imageBase64?.trim() ?? '';

    if (b64.isNotEmpty) {
      try {
        return Image.memory(base64Decode(b64), fit: BoxFit.cover);
      } catch (_) {
        return const _ImgPlaceholder();
      }
    }
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _ImgPlaceholder(),
      );
    }
    return const _ImgPlaceholder();
  }
}

class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(CupertinoIcons.photo, color: Color(0xFFC7C7CC), size: 28),
      );
}

// ── State card ────────────────────────────────────────────────────────────────

class _StateCard extends StatelessWidget {
  const _StateCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFC7C7CC), size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
