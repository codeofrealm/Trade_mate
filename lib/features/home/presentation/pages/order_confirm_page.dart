import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

enum _PayMethod { razorpay, gpay, upi, cod }

extension _PayMethodX on _PayMethod {
  String get label {
    switch (this) {
      case _PayMethod.razorpay:
        return 'Razorpay Payment Link';
      case _PayMethod.gpay:
        return 'Google Pay';
      case _PayMethod.upi:
        return 'UPI';
      case _PayMethod.cod:
        return 'Cash On Delivery';
    }
  }

  IconData get icon {
    switch (this) {
      case _PayMethod.razorpay:
        return CupertinoIcons.creditcard_fill;
      case _PayMethod.gpay:
        return CupertinoIcons.device_phone_portrait;
      case _PayMethod.upi:
        return CupertinoIcons.qrcode;
      case _PayMethod.cod:
        return CupertinoIcons.money_dollar_circle;
    }
  }

  Color get color {
    switch (this) {
      case _PayMethod.razorpay:
        return const Color(0xFF007AFF);
      case _PayMethod.gpay:
        return const Color(0xFF1A73E8);
      case _PayMethod.upi:
        return const Color(0xFF5856D6);
      case _PayMethod.cod:
        return const Color(0xFF0C8B3D);
    }
  }
}

class _RazorpayPaymentLink {
  const _RazorpayPaymentLink._();

  static const id = 'cust_SnBZuCByJgdeTK';
  static const createdAt = '09 May 2026';
  static const amount = 63.0;
  static const link = 'https://rzp.io/rzp/fmpxzdRT';
  static const status = 'Issued';
  static const customerEmail = 'rahul63794@gmail.com';
}

// ── Page ──────────────────────────────────────────────────────────────────────

class OrderConfirmPage extends StatefulWidget {
  const OrderConfirmPage({super.key});

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  _PayMethod _selected = _PayMethod.razorpay;
  bool _isOrdering = false;
  bool _paymentOpened = false;

  OrderConfirmPageArgs get _args {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OrderConfirmPageArgs) return args;
    return OrderConfirmPageArgs(
      product: AdminProduct(
        id: '',
        name: '',
        description: '',
        category: '',
        price: 0,
        stock: 0,
        soldCount: 0,
        reviewCount: 0,
        rating: 0,
        isActive: false,
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_isOrdering) return;
    final args = _args;
    final total = args.product.price * args.quantity;

    if (!_paymentOpened) {
      await _openSelectedPayment(total);
      return;
    }

    final address = await HomeUserProfileService.instance.streamAddress().first;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOrdering = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
  }

  void _selectMethod(_PayMethod method) {
    setState(() {
      _selected = method;
      _paymentOpened = false;
    });
  }

  Future<void> _openSelectedPayment(double orderTotal) {
    return switch (_selected) {
      _PayMethod.razorpay => _openRazorpayPaymentLink(orderTotal),
      _PayMethod.gpay => _openNativeUpiPayment(
        orderTotal: orderTotal,
        preferGooglePay: true,
      ),
      _PayMethod.upi => _openNativeUpiPayment(
        orderTotal: orderTotal,
        preferGooglePay: false,
      ),
      _PayMethod.cod => _openCashOnDelivery(orderTotal),
    };
  }

  Future<void> _openRazorpayPaymentLink(double orderTotal) async {
    if (orderTotal != _RazorpayPaymentLink.amount && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Razorpay link amount is Rs ${_RazorpayPaymentLink.amount.toStringAsFixed(2)}. Current order is Rs ${orderTotal.toStringAsFixed(2)}.',
          ),
        ),
      );
    }

    final uri = Uri.parse(_RazorpayPaymentLink.link);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No browser or browser handler available for Razorpay link.',
            ),
          ),
        );
        return;
      }

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;

      if (opened) {
        setState(() => _paymentOpened = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Razorpay opened. Complete payment, then confirm order.',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open Razorpay payment link.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to launch Razorpay payment link.'),
        ),
      );
    }
  }

  Future<void> _openNativeUpiPayment({
    required double orderTotal,
    required bool preferGooglePay,
  }) async {
    final uri = _buildUpiUri(orderTotal, preferGooglePay: preferGooglePay);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              preferGooglePay
                  ? 'Google Pay is not installed or cannot handle this payment request. Try UPI or Razorpay.'
                  : 'No UPI app available to handle payment. Try Razorpay.',
            ),
          ),
        );
        return;
      }

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;

      if (opened) {
        setState(() => _paymentOpened = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${preferGooglePay ? 'Google Pay' : 'UPI app'} opened. Complete payment, then confirm order.',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            preferGooglePay
                ? 'Unable to open Google Pay. Try UPI or Razorpay.'
                : 'Unable to open a UPI app. Try Razorpay.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            preferGooglePay
                ? 'Google Pay could not be launched. Use UPI or Razorpay instead.'
                : 'UPI payment failed to start. Use Razorpay instead.',
          ),
        ),
      );
    }
  }

  Future<void> _openCashOnDelivery(double orderTotal) async {
    if (!mounted) return;
    setState(() => _paymentOpened = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cash on Delivery selected. Tap Place Order to finish.'),
      ),
    );
  }

  Uri _buildUpiUri(double orderTotal, {required bool preferGooglePay}) {
    final params = <String, String>{
      'pa': 'merchant@upi',
      'pn': 'TradeMate',
      'tn': 'TradeMate order ${_args.product.name}',
      'am': orderTotal.toStringAsFixed(2),
      'cu': 'INR',
    };
    if (preferGooglePay) {
      return Uri(
        scheme: 'gpay',
        host: 'upi',
        path: 'pay',
        queryParameters: params,
      );
    }

    return Uri(scheme: 'upi', host: 'pay', queryParameters: params);
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
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 15,
                      color: Color(0xFF34C759),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Product Verified',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DetailRow(label: 'Product', value: product.name),
                _DetailRow(label: 'Category', value: product.category),
                _DetailRow(
                  label: 'Unit Price',
                  value: 'Rs ${product.price.toStringAsFixed(2)}',
                ),
                _DetailRow(label: 'Quantity', value: '${args.quantity}'),
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
                        color: Color(0xFF000000),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rs ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF007AFF),
                        letterSpacing: -0.4,
                      ),
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
                  onTap: () => _selectMethod(method),
                );
              }).toList(),
            ),
          ),
          if (_selected == _PayMethod.razorpay) ...[
            const SizedBox(height: 12),
            _RazorpayTicketCard(
              orderAmount: total,
              paymentOpened: _paymentOpened,
              onOpenPayment: () => _openRazorpayPaymentLink(total),
            ),
          ] else if (_selected == _PayMethod.cod) ...[
            const SizedBox(height: 12),
            _CashOnDeliveryCard(paymentOpened: _paymentOpened),
          ] else ...[
            const SizedBox(height: 12),
            _NativePaymentCard(
              method: _selected,
              orderAmount: total,
              paymentOpened: _paymentOpened,
              onOpenPayment: () => _openSelectedPayment(total),
            ),
          ],
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
                        !_paymentOpened
                            ? 'Pay with ${_selected.label}'
                            : 'Place Order - Rs ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
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

class _RazorpayTicketCard extends StatelessWidget {
  const _RazorpayTicketCard({
    required this.orderAmount,
    required this.paymentOpened,
    required this.onOpenPayment,
  });

  final double orderAmount;
  final bool paymentOpened;
  final VoidCallback onOpenPayment;

  bool get _amountMatches => orderAmount == _RazorpayPaymentLink.amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.creditcard_fill,
                  color: Color(0xFF007AFF),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Razorpay Payment Ticket',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Open payment link, complete payment, then confirm.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Payment Link Id', value: _RazorpayPaymentLink.id),
          _DetailRow(
            label: 'Customer Email',
            value: _RazorpayPaymentLink.customerEmail,
          ),
          _DetailRow(
            label: 'Created At',
            value: _RazorpayPaymentLink.createdAt,
          ),
          _DetailRow(
            label: 'Amount',
            value: 'Rs ${_RazorpayPaymentLink.amount.toStringAsFixed(2)}',
          ),
          _DetailRow(label: 'Receipt No.', value: _RazorpayPaymentLink.id),
          const _DetailRow(label: 'Customer', value: 'TradeMate Customer'),
          _DetailRow(label: 'Status', value: _RazorpayPaymentLink.status),
          _DetailRow(label: 'Payment Link', value: _RazorpayPaymentLink.link),
          if (!_amountMatches) ...[
            const SizedBox(height: 6),
            Text(
              'Warning: this link is for Rs ${_RazorpayPaymentLink.amount.toStringAsFixed(2)}, but this order is Rs ${orderAmount.toStringAsFixed(2)}.',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onOpenPayment,
              icon: Icon(
                paymentOpened
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.arrow_up_right_square,
                size: 17,
              ),
              label: Text(paymentOpened ? 'Open Again' : 'Open Razorpay Link'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashOnDeliveryCard extends StatelessWidget {
  const _CashOnDeliveryCard({required this.paymentOpened});

  final bool paymentOpened;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C8B3D).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.money_dollar_circle,
                  color: Color(0xFF0C8B3D),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Cash on Delivery',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pay when your order is delivered to your address.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Payment Mode', value: 'Cash on Delivery'),
          _DetailRow(label: 'Customer', value: 'TradeMate Customer'),
          _DetailRow(
            label: 'Status',
            value: paymentOpened ? 'Confirmed' : 'Ready',
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(CupertinoIcons.checkmark_circle_fill, size: 17),
              label: Text(paymentOpened ? 'Selected' : 'Tap Place Order'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NativePaymentCard extends StatelessWidget {
  const _NativePaymentCard({
    required this.method,
    required this.orderAmount,
    required this.paymentOpened,
    required this.onOpenPayment,
  });

  final _PayMethod method;
  final double orderAmount;
  final bool paymentOpened;
  final VoidCallback onOpenPayment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: method.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(method.icon, color: method.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${method.label} Ticket',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Opens your payment app directly, not a web page.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: 'Payment Mode', value: method.label),
          _DetailRow(label: 'Customer', value: 'TradeMate Customer'),
          _DetailRow(
            label: 'Amount',
            value: 'Rs ${orderAmount.toStringAsFixed(2)}',
          ),
          _DetailRow(
            label: 'Status',
            value: paymentOpened ? 'Opened' : 'Ready',
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onOpenPayment,
              icon: Icon(
                paymentOpened
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.arrow_up_right_square,
                size: 17,
              ),
              label: Text(
                paymentOpened ? 'Open Again' : 'Open ${method.label}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                      color: Color(0xFF000000),
                    ),
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
                      ? const Icon(
                          CupertinoIcons.checkmark,
                          size: 12,
                          color: Colors.white,
                        )
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF000000),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
