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
  final Set<String> _selectedCartIds = {};

  bool get _isSelectionMode => _selectedCartIds.isNotEmpty;

  void _toggleSelection(String cartId) {
    setState(() {
      if (_selectedCartIds.contains(cartId)) {
        _selectedCartIds.remove(cartId);
      } else {
        _selectedCartIds.add(cartId);
      }
    });
  }

  void _clearSelection() {
    if (_selectedCartIds.isEmpty) {
      return;
    }
    setState(_selectedCartIds.clear);
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedCartIds.isEmpty) {
      return;
    }

    final ids = _selectedCartIds.toList();
    final deleted = await _confirmAndDeleteItems(ids);
    if (!deleted || !mounted) {
      return;
    }

    setState(_selectedCartIds.clear);
  }

  Future<bool> _confirmAndDeleteItems(List<String> ids) async {
    if (ids.isEmpty) {
      return false;
    }

    final count = ids.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(count == 1 ? 'Delete cart item?' : 'Delete cart items?'),
          content: Text(
            count == 1
                ? 'This product will be removed from your cart.'
                : '$count selected products will be removed from your cart.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return false;
    }

    try {
      for (final id in ids) {
        await HomeProductService.instance.removeCartItem(id);
      }
      if (!mounted) {
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1 ? 'Cart item deleted.' : '$count cart items deleted.',
          ),
        ),
      );
    } on HomeProductException catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return false;
    }

    return true;
  }

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
          productName: items.length == 1
              ? items.first.productName
              : 'Cart Items',
          quantity: totalCount,
          totalAmount: totalAmount,
          orderId: firstOrderId,
        ),
      );
    } on HomeProductException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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
        final validIds = items.map((item) => item.id).toSet();
        if (_selectedCartIds.any((id) => !validIds.contains(id))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(
              () =>
                  _selectedCartIds.removeWhere((id) => !validIds.contains(id)),
            );
          });
        }
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
                items.isNotEmpty &&
                address.isComplete &&
                !_isPlacingOrder &&
                !_isSelectionMode;

            return LayoutBuilder(
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 158),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cart',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1D26),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _isSelectionMode
                                        ? '${_selectedCartIds.length} selected'
                                        : 'Your interested products and totals',
                                    style: const TextStyle(
                                      color: Color(0xFF6D7587),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (_isSelectionMode) ...[
                                  IconButton(
                                    tooltip: 'Clear selection',
                                    onPressed: _clearSelection,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete selected',
                                    onPressed: _deleteSelectedItems,
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFFF3B30),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            _CartSummaryCard(
                              totalCount: totalCount,
                              totalAmount: totalAmount,
                            ),
                            const SizedBox(height: 6),
                            _AddressPreviewCard(address: address),
                            const SizedBox(height: 8),
                            if (items.isEmpty)
                              const _EmptyCard(
                                message: 'No products added to cart yet.',
                              )
                            else
                              ...items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _CartItemCard(
                                    item: item,
                                    isSelected: _selectedCartIds.contains(
                                      item.id,
                                    ),
                                    selectionMode: _isSelectionMode,
                                    onToggleSelection: () =>
                                        _toggleSelection(item.id),
                                    onDelete: () =>
                                        _confirmAndDeleteItems([item.id]),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: MediaQuery.paddingOf(context).bottom + 92,
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
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              address.isComplete
                                  ? 'Place Order (Rs ${totalAmount.toStringAsFixed(2)})'
                                  : 'Complete address to order',
                              maxLines: 1,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Items',
                  style: TextStyle(color: Color(0xFF687386), fontSize: 12.5),
                ),
                const SizedBox(height: 1),
                Text(
                  '$totalCount',
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 22,
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
                  style: TextStyle(color: Color(0xFF687386), fontSize: 12.5),
                ),
                const SizedBox(height: 1),
                Text(
                  'Rs ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 18,
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
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cart',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D26),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6D7587),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3EE)),
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
  const _CartItemCard({
    required this.item,
    required this.isSelected,
    required this.selectionMode,
    required this.onToggleSelection,
    required this.onDelete,
  });

  final HomeCartItem item;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onToggleSelection;
  final Future<bool> Function() onDelete;

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

  Future<void> _deleteItem() async {
    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);
    await widget.onDelete();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return GestureDetector(
      onLongPress: widget.onToggleSelection,
      onTap: widget.selectionMode ? widget.onToggleSelection : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? const Color(0xFF007AFF)
                : const Color(0xFFDCE3EE),
            width: widget.isSelected ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _CartImage(item: item),
                if (widget.isSelected)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
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
                  if (item.productCategory.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.productCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
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
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Delete item',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: _isLoading || widget.selectionMode
                      ? null
                      : _deleteItem,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF3B30),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 2),
                _QuantityStepper(
                  quantity: item.quantity,
                  enabled: !_isLoading && !widget.selectionMode,
                  onIncrease: () => _changeQuantity(item.quantity + 1),
                  onDecrease: () => _changeQuantity(item.quantity - 1),
                ),
              ],
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 50,
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

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.enabled,
    required this.onIncrease,
    required this.onDecrease,
  });

  final int quantity;
  final bool enabled;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE3EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: enabled,
            onPressed: onDecrease,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: enabled,
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      color: const Color(0xFF007AFF),
      disabledColor: const Color(0xFFCBD5E1),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3EE)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }
}
