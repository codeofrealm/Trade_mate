import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../../app/app_routes.dart';
import '../../../data/home_product_service.dart';
import '../../../data/home_user_profile_service.dart';
import '../../../data/models/home_cart_item.dart';
import '../../../data/models/home_user_address.dart';
import '../../pages/order_success_page.dart';

class HomeCartTab extends StatefulWidget {
  const HomeCartTab({super.key});

  @override
  State<HomeCartTab> createState() => _HomeCartTabState();
}

class _HomeCartTabState extends State<HomeCartTab> {
  bool _isPlacingOrder = false;

  Future<void> _placeCartOrder({
    required List<HomeCartItem> items,
    required HomeUserAddress address,
    required double totalAmount,
    required int totalCount,
  }) async {
    if (_isPlacingOrder) {
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final firstOrderId = await HomeProductService.instance.placeCartOrder(
        items: items,
        address: address,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamed(
        AppRoutes.orderSuccess,
        arguments: OrderSuccessPageArgs(
          productName: items.length == 1 ? items.first.productName : 'Cart Items',
          quantity: totalCount,
          totalAmount: totalAmount,
          orderId: firstOrderId,
        ),
      );
    } on HomeProductException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeCartItem>>(
      stream: HomeProductService.instance.streamCartItems(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _CartBaseLayout(
            subtitle: 'Unable to load cart items',
            child: _EmptyCard(message: 'Please try again later.'),
          );
        }

        if (!snapshot.hasData) {
          return const _CartBaseLayout(
            subtitle: 'Loading your interested products',
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final items = snapshot.data!;
        final totalAmount = items.fold<double>(
          0,
          (sum, item) => sum + item.totalPrice,
        );
        final totalCount = items.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        );

        return StreamBuilder<HomeUserAddress>(
          stream: HomeUserProfileService.instance.streamAddress(),
          builder: (context, addressSnapshot) {
            final address = addressSnapshot.data ?? HomeUserAddress.empty;
            final canPlaceOrder =
                items.isNotEmpty && address.isComplete && !_isPlacingOrder;

            return LayoutBuilder(
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cart',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1D26),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your interested products and totals',
                              style: TextStyle(
                                color: Color(0xFF6D7587),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _CartSummaryCard(
                              totalCount: totalCount,
                              totalAmount: totalAmount,
                            ),
                            const SizedBox(height: 12),
                            _AddressPreviewCard(address: address),
                            const SizedBox(height: 12),
                            if (items.isEmpty)
                              const _EmptyCard(
                                message: 'No products added to cart yet.',
                              )
                            else
                              ...items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _CartItemCard(item: item),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: canPlaceOrder
                                ? () => _placeCartOrder(
                                      items: items,
                                      address: address,
                                      totalAmount: totalAmount,
                                      totalCount: totalCount,
                                    )
                                : null,
                            icon: _isPlacingOrder
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.shopping_bag_outlined),
                            label: Text(
                              address.isComplete
                                  ? 'Place Order (Rs ${totalAmount.toStringAsFixed(2)})'
                                  : 'Complete address to order',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({required this.totalCount, required this.totalAmount});

  final int totalCount;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Items',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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

class _CartBaseLayout extends StatelessWidget {
  const _CartBaseLayout({required this.subtitle, required this.child});

  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cart',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D26),
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6D7587),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _AddressPreviewCard extends StatelessWidget {
  const _AddressPreviewCard({required this.address});

  final HomeUserAddress address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Address',
            style: TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            address.isComplete
                ? '${address.fullName}, ${address.line1}, ${address.city}, ${address.state}'
                : 'Address incomplete. Update full address in Profile page.',
            style: TextStyle(
              color: address.isComplete
                  ? const Color(0xFF475569)
                  : const Color(0xFFB45309),
              fontWeight: address.isComplete
                  ? FontWeight.w500
                  : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  const _CartItemCard({required this.item});

  final HomeCartItem item;

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  bool _isLoading = false;

  Future<void> _changeQuantity(int nextQuantity) async {
    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (nextQuantity <= 0) {
        await HomeProductService.instance.removeCartItem(widget.item.id);
      } else {
        await HomeProductService.instance.updateCartQuantity(
          cartDocId: widget.item.id,
          quantity: nextQuantity,
        );
      }
    } on HomeProductException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _CartImage(item: item),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.productCategory,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs ${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                onPressed: _isLoading
                    ? null
                    : () => _changeQuantity(item.quantity + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
              Text(
                '${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: _isLoading
                    ? null
                    : () => _changeQuantity(item.quantity - 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartImage extends StatelessWidget {
  const _CartImage({required this.item});

  final HomeCartItem item;

  @override
  Widget build(BuildContext context) {
    final base64Data = item.productImageBase64?.trim() ?? '';
    final url = item.productImageUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        color: const Color(0xFFE2E8F0),
        child: _CartImageContent(base64Data: base64Data, url: url),
      ),
    );
  }
}

class _CartImageContent extends StatelessWidget {
  const _CartImageContent({required this.base64Data, required this.url});

  final String base64Data;
  final String url;

  @override
  Widget build(BuildContext context) {
    if (base64Data.isNotEmpty) {
      try {
        return Image.memory(base64Decode(base64Data), fit: BoxFit.cover);
      } catch (_) {
        return const Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF64748B),
        );
      }
    }

    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF64748B),
          );
        },
      );
    }

    return const Icon(Icons.shopping_bag_outlined, color: Color(0xFF64748B));
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }
}
