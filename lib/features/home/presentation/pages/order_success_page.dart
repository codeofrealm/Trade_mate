import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

class OrderSuccessPageArgs {
  const OrderSuccessPageArgs({
    required this.productName,
    required this.quantity,
    required this.totalAmount,
    required this.orderId,
  });

  final String productName;
  final int quantity;
  final double totalAmount;
  final String orderId;
}

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key});

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickController;
  bool _isVerifying = true;
  bool _isCompleted = false;
  bool _showCloseButton = false;

  OrderSuccessPageArgs get _args {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is OrderSuccessPageArgs) {
      return args;
    }

    return const OrderSuccessPageArgs(
      productName: 'Product',
      quantity: 1,
      totalAmount: 0,
      orderId: '',
    );
  }

  @override
  void initState() {
    super.initState();
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _runVerificationFlow();
  }

  @override
  void dispose() {
    _tickController.dispose();
    super.dispose();
  }

  Future<void> _runVerificationFlow() async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) {
      return;
    }

    setState(() {
      _isVerifying = false;
      _isCompleted = true;
    });
    unawaited(_tickController.forward());

    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) {
      return;
    }

    setState(() => _showCloseButton = true);
  }

  void _closeFlow() {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == AppRoutes.home || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;

    return PopScope(
      canPop: _showCloseButton,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4FFF8), Color(0xFFE2FCEB), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 430),
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFCFF1DB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 6),
                      _isVerifying
                          ? const SizedBox(
                              width: 74,
                              height: 74,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                color: Color(0xFF16A34A),
                              ),
                            )
                          : ScaleTransition(
                              scale: CurvedAnimation(
                                parent: _tickController,
                                curve: Curves.elasticOut,
                              ),
                              child: Container(
                                width: 78,
                                height: 78,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16A34A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isCompleted
                            ? const Text(
                                'Order Verified',
                                key: ValueKey('completed'),
                                style: TextStyle(
                                  color: Color(0xFF14532D),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : const Text(
                                'Verifying Order',
                                key: ValueKey('verifying'),
                                style: TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isCompleted
                            ? 'Payment and order verification completed successfully.'
                            : 'Please wait while we verify your order details.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6FFFA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD5F5E1)),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'Product',
                              value: args.productName.trim().isEmpty
                                  ? 'Product'
                                  : args.productName,
                            ),
                            const SizedBox(height: 6),
                            _InfoRow(
                              label: 'Quantity',
                              value: args.quantity.toString(),
                            ),
                            const SizedBox(height: 6),
                            _InfoRow(
                              label: 'Total',
                              value:
                                  'Rs ${args.totalAmount.toStringAsFixed(2)}',
                            ),
                            if (args.orderId.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _InfoRow(label: 'Order ID', value: args.orderId),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        opacity: _showCloseButton ? 1 : 0,
                        duration: const Duration(milliseconds: 240),
                        child: IgnorePointer(
                          ignoring: !_showCloseButton,
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _closeFlow,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Close'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}
