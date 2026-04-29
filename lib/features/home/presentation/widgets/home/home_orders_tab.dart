import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/app_routes.dart';
import '../../../data/home_product_service.dart';
import '../../../data/models/home_user_order.dart';
import '../../../utils/home_helpers.dart';
import '../../pages/product_details_page.dart';
import '../orders/home_order_tracking_widgets.dart';
import 'home_tab_scaffold.dart';

class HomeOrdersTab extends StatefulWidget {
  const HomeOrdersTab({super.key});

  static const _supportPhone = '+91 9159830802';

  @override
  State<HomeOrdersTab> createState() => _HomeOrdersTabState();
}

class _HomeOrdersTabState extends State<HomeOrdersTab> {
  final Set<String> _deliveryNotifiedIds = {};
  final Set<String> _cancelNotifiedIds = {};
  final List<HomeNotifBanner> _banners = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeUserOrder>>(
      stream: HomeProductService.instance.streamMyOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const HomeTabScaffold(
            title: 'My Orders',
            subtitle: 'Track delivery updates and support actions',
            child: _InfoCard(
              icon: Icons.error_outline_rounded,
              message: 'Unable to load your orders right now.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const HomeTabScaffold(
            title: 'My Orders',
            subtitle: 'Track delivery updates and support actions',
            child: _InfoCard(
              icon: Icons.local_shipping_outlined,
              message: 'Loading your order tracking details...',
              isLoading: true,
            ),
          );
        }

        final orders = snapshot.data!;
        final activeCount =
            orders.where((o) => !o.isDelivered && !o.isCancelled).length;
        final deliveredCount = orders.where((o) => o.isDelivered).length;
        final cancelledCount = orders.where((o) => o.isCancelled).length;

        final newlyDelivered = orders
            .where((o) => o.isDelivered && !_deliveryNotifiedIds.contains(o.id))
            .toList();
        final newlyCancelled = orders
            .where((o) => o.isCancelled && !_cancelNotifiedIds.contains(o.id))
            .toList();

        if (newlyDelivered.isNotEmpty || newlyCancelled.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              for (final o in newlyDelivered) {
                _deliveryNotifiedIds.add(o.id);
                _banners.add(HomeNotifBanner(
                  id: o.id,
                  message:
                      '✅  Order delivered: ${o.productName.isEmpty ? homeShortId(o.id) : o.productName}',
                  color: const Color(0xFF34C759),
                ));
              }
              for (final o in newlyCancelled) {
                _cancelNotifiedIds.add(o.id);
                _banners.add(HomeNotifBanner(
                  id: o.id,
                  message:
                      '❌  Order cancelled: ${o.productName.isEmpty ? homeShortId(o.id) : o.productName}',
                  color: const Color(0xFFFF3B30),
                ));
              }
            });
          });
        }

        final activeOrders = orders.where((o) => !o.isDelivered && !o.isCancelled).toList();

        return HomeTabScaffold(
          title: 'My Orders',
          subtitle: 'Track orders, call customer care, and send messages',
          child: Column(
            children: [
              // ── Active orders warning banner ──
              if (activeOrders.isNotEmpty) ...[
                _ActiveOrdersWarningBanner(count: activeOrders.length),
                const SizedBox(height: 8),
              ],
              if (_banners.isNotEmpty) ...[
                ..._banners.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HomeBannerCard(
                        banner: b,
                        onDismiss: () => setState(
                            () => _banners.removeWhere((x) => x.id == b.id)),
                      ),
                    )),
                const SizedBox(height: 4),
              ],
              HomeOrdersSummaryCard(
                total: orders.length,
                active: activeCount,
                delivered: deliveredCount,
                cancelled: cancelledCount,
              ),
              const SizedBox(height: 12),
              if (orders.isEmpty)
                const _InfoCard(
                  icon: Icons.receipt_long_outlined,
                  message: 'No orders yet. Place a product order to track it here.',
                )
              else
                ...orders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: HomeOrderTrackingCard(
                      order: order,
                      onTrack: () => _openTrackSheet(context, order),
                      onCall: () => _onCallSupport(context, order),
                      onMessage: () => _onMessageSupport(context, order),
                      onProductTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.productDetails,
                        arguments: ProductDetailsPageArgs(
                          productId: order.productId,
                          productName: order.productName,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _onCallSupport(BuildContext context, HomeUserOrder order) {
    final uri = Uri(scheme: 'tel', path: HomeOrdersTab._supportPhone);
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication).then((ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(ok
              ? 'Opening customer care (${HomeOrdersTab._supportPhone}).'
              : 'Unable to open dialer. Call ${HomeOrdersTab._supportPhone}.'),
        ));
    }));
  }

  void _onMessageSupport(BuildContext context, HomeUserOrder order) {
    final uri = Uri(
      scheme: 'sms',
      path: HomeOrdersTab._supportPhone,
      queryParameters: <String, String>{
        'body': 'Hi, I need help with my order ${homeShortId(order.id)}.',
      },
    );
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication).then((ok) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(ok
              ? 'Opening SMS for order ${homeShortId(order.id)}.'
              : 'Unable to open SMS. Message ${HomeOrdersTab._supportPhone}.'),
        ));
    }));
  }

  void _openTrackSheet(BuildContext context, HomeUserOrder order) {
    final steps = _buildTrackSteps(order);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.productName.isEmpty ? 'Order Tracking' : order.productName,
              style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text(
              'Ordered ${homeTimeAgo(order.createdAt)} • ${homeFullDate(order.createdAt)}',
              style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.8,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      step.$2
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: step.$2
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step.$1,
                      style: TextStyle(
                        color: step.$2
                            ? const Color(0xFF166534)
                            : const Color(0xFF64748B),
                        fontWeight:
                            step.$2 ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<(String, bool)> _buildTrackSteps(HomeUserOrder order) {
  const steps = ['Order Placed', 'Packed', 'Shipped', 'Delivered'];
  final safeStep = order.progressStepIndex.clamp(0, steps.length - 1);
  final values = <(String, bool)>[];
  for (var i = 0; i < steps.length; i++) {
    values.add((steps[i], !order.isCancelled && i <= safeStep));
  }
  if (order.isCancelled) values.add(('Cancelled', true));
  return values;
}

class _ActiveOrdersWarningBanner extends StatelessWidget {
  const _ActiveOrdersWarningBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC00).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9500), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You have $count active order${count > 1 ? 's' : ''} in progress. Track below.',
              style: const TextStyle(
                color: Color(0xFF7A4F00),
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.message, this.isLoading = false});
  final IconData icon;
  final String message;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
