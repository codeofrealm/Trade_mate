import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../admin/data/models/admin_product.dart';
import '../../data/home_product_service.dart';
import '../../data/home_user_profile_service.dart';
import 'order_success_page.dart';

// ── Args ──────────────────────────────────────────────────────────────────────

class OrderConfirmPageArgs {
  const OrderConfirmPageArgs({required this.product, this.quantity = 1});
  final AdminProduct product;
  final int quantity;
}

// ── Payment method ────────────────────────────────────────────────────────────

enum _PayMethod { cod, gpay, upi, other }

extension _PayMethodX on _PayMethod {
  String get label {
    switch (this) {
      case _PayMethod.cod:  return 'Cash on Delivery';
      case _PayMethod.gpay: return 'Google Pay';
      case _PayMethod.upi:  return 'UPI';
      case _PayMethod.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case _PayMethod.cod:  return CupertinoIcons.money_dollar_circle_fill;
      case _PayMethod.gpay: return CupertinoIcons.device_phone_portrait;
      case _PayMethod.upi:  return CupertinoIcons.qrcode;
      case _PayMethod.other: return CupertinoIcons.creditcard_fill;
    }
  }

  Color get color {
    switch (this) {
      case _PayMethod.cod:  return const Color(0xFF34C759);
      case _PayMethod.gpay: return const Color(0xFF007AFF);
      case _PayMethod.upi:  return const Color(0xFF5856D6);
      case _PayMethod.other: return const Color(0xFFFF9500);
    }
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class OrderConfirmPage extends StatefulWidget {
  const OrderConfirmPage({super.key});

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  _PayMethod _selected = _PayMethod.cod;
  bool _isOrdering = false;

  OrderConfirmPageArgs get _args {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OrderConfirmPageArgs) return args;
    return OrderConfirmPageArgs(
      product: AdminProduct(
        id: '', name: '', description: '', category: '',
        price: 0, stock: 0, soldCount: 0, reviewCount: 0,
        rating: 0, isActive: false,
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_isOrdering) return;
    final args = _args;

    final address =
        await HomeUserProfileService.instance.streamAddress().first;
    if (!mounted) return;

    if (!address.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add your delivery address in Profile.'),
          action: SnackBarAction(
            label: 'Profile',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.homeProfile),
          ),
        ),
      );
      return;
    }

    setState(() => _isOrdering = true);
    try {
      final orderId = await HomeProductService.instance.placeOrder(
        product: args.product,
        address: address,
        quantity: args.quantity,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacementNamed(
        AppRoutes.orderSuccess,
        arguments: OrderSuccessPageArgs(
          productName: args.product.name,
          quantity: args.quantity,
          totalAmount: args.product.price * args.quantity,
          orderId: orderId,
        ),
      );
    } on HomeProductException catch (e) {
      if (!mounted) return;
      setState(() => _isOrdering = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOrdering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    final product = args.product;
    final total = product.price * args.quantity;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Confirm Order'),
        backgroundColor: const Color(0xFFF2F2F7),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // ── Product verification card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // verified badge
                Row(
                  children: [
                    const Icon(CupertinoIcons.checkmark_seal_fill,
                        size: 15, color: Color(0xFF34C759)),
                    const SizedBox(width: 6),
                    const Text(
                      'Product Verified',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34C759)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DetailRow(label: 'Product', value: product.name),
                _DetailRow(label: 'Category', value: product.category),
                _DetailRow(
                    label: 'Unit Price',
                    value: 'Rs ${product.price.toStringAsFixed(2)}'),
                _DetailRow(
                    label: 'Quantity', value: '${args.quantity}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFE5E5EA)),
                ),
                Row(
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000000)),
                    ),
                    const Spacer(),
                    Text(
                      'Rs ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF007AFF),
                          letterSpacing: -0.4),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Payment method label ──
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
                letterSpacing: -0.3,
              ),
            ),
          ),

          // ── Payment options ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Column(
              children: _PayMethod.values.map((method) {
                final isLast = method == _PayMethod.values.last;
                return _PayMethodTile(
                  method: method,
                  isSelected: _selected == method,
                  showDivider: !isLast,
                  onTap: () => setState(() => _selected = method),
                );
              }).toList(),
            ),
          ),
        ],
      ),

      // ── Place order button ──
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _isOrdering ? null : _placeOrder,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isOrdering
                ? const CupertinoActivityIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.bag_fill, size: 17),
                      const SizedBox(width: 8),
                      Text(
                        'Place Order  •  Rs ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Payment method tile ───────────────────────────────────────────────────────

class _PayMethodTile extends StatelessWidget {
  const _PayMethodTile({
    required this.method,
    required this.isSelected,
    required this.showDivider,
    required this.onTap,
  });

  final _PayMethod method;
  final bool isSelected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(method.icon, color: method.color, size: 19),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    method.label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF000000)),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF007AFF)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFC7C7CC),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(CupertinoIcons.checkmark,
                          size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 65, color: Color(0xFFE5E5EA)),
      ],
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
