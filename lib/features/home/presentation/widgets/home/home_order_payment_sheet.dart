import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../app/app_routes.dart';
import '../../../../admin/data/models/admin_product.dart';
import '../../../data/home_product_service.dart';
import '../../../data/home_user_profile_service.dart';
import '../../pages/order_success_page.dart';

// ── Payment method enum ───────────────────────────────────────────────────────

enum _PayMethod { cod, gpay, upi, other }

extension _PayMethodX on _PayMethod {
  String get label {
    switch (this) {
      case _PayMethod.cod:
        return 'Cash on Delivery';
      case _PayMethod.gpay:
        return 'Google Pay';
      case _PayMethod.upi:
        return 'UPI';
      case _PayMethod.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case _PayMethod.cod:
        return CupertinoIcons.money_dollar_circle_fill;
      case _PayMethod.gpay:
        return CupertinoIcons.device_phone_portrait;
      case _PayMethod.upi:
        return CupertinoIcons.qrcode;
      case _PayMethod.other:
        return CupertinoIcons.creditcard_fill;
    }
  }

  Color get color {
    switch (this) {
      case _PayMethod.cod:
        return const Color(0xFF34C759);
      case _PayMethod.gpay:
        return const Color(0xFF007AFF);
      case _PayMethod.upi:
        return const Color(0xFF5856D6);
      case _PayMethod.other:
        return const Color(0xFFFF9500);
    }
  }
}

// ── Show helper ───────────────────────────────────────────────────────────────

Future<void> showOrderPaymentSheet({
  required BuildContext context,
  required AdminProduct product,
  int quantity = 1,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderPaymentSheet(product: product, quantity: quantity),
  );
}

// ── Sheet widget ──────────────────────────────────────────────────────────────

class _OrderPaymentSheet extends StatefulWidget {
  const _OrderPaymentSheet({required this.product, required this.quantity});
  final AdminProduct product;
  final int quantity;

  @override
  State<_OrderPaymentSheet> createState() => _OrderPaymentSheetState();
}

class _OrderPaymentSheetState extends State<_OrderPaymentSheet> {
  _PayMethod _selected = _PayMethod.cod;
  bool _isOrdering = false;

  double get _total => widget.product.price * widget.quantity;

  Future<void> _placeOrder() async {
    if (_isOrdering) return;

    final address =
        await HomeUserProfileService.instance.streamAddress().first;

    if (!mounted) return;

    if (!address.isComplete) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please add your delivery address in Profile.'),
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
        product: widget.product,
        address: address,
        quantity: widget.quantity,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await Navigator.of(context).pushNamed(
        AppRoutes.orderSuccess,
        arguments: OrderSuccessPageArgs(
          productName: widget.product.name,
          quantity: widget.quantity,
          totalAmount: _total,
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D1D6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title
                  const Text(
                    'Confirm Order',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Product verification card ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.checkmark_seal_fill,
                                size: 14, color: Color(0xFF34C759)),
                            const SizedBox(width: 5),
                            const Text(
                              'Product Verified',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF34C759)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                            label: 'Product',
                            value: widget.product.name),
                        _DetailRow(
                            label: 'Category',
                            value: widget.product.category),
                        _DetailRow(
                            label: 'Unit Price',
                            value:
                                'Rs ${widget.product.price.toStringAsFixed(2)}'),
                        _DetailRow(
                            label: 'Quantity',
                            value: '${widget.quantity}'),
                        const Divider(
                            height: 16, color: Color(0xFFE5E5EA)),
                        Row(
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF000000)),
                            ),
                            const Spacer(),
                            Text(
                              'Rs ${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF007AFF),
                                  letterSpacing: -0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Payment method ──
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: Column(
                      children: _PayMethod.values.map((method) {
                        final isLast =
                            method == _PayMethod.values.last;
                        return _PayMethodTile(
                          method: method,
                          isSelected: _selected == method,
                          showDivider: !isLast,
                          onTap: () =>
                              setState(() => _selected = method),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Place order button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isOrdering ? null : _placeOrder,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isOrdering
                          ? const CupertinoActivityIndicator(
                              color: Colors.white)
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    CupertinoIcons.bag_fill,
                                    size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Place Order • Rs ${_total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
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
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: method.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(method.icon,
                      color: method.color, size: 18),
                ),
                const SizedBox(width: 12),
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
          const Divider(
              height: 1, indent: 62, color: Color(0xFFE5E5EA)),
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
      padding: const EdgeInsets.only(bottom: 6),
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
