import 'package:flutter/material.dart';

import '../../../../../app/app_routes.dart';
import '../../../data/models/home_user_order.dart';
import '../../../utils/home_helpers.dart';
import '../../pages/product_details_page.dart';
import '../../viewmodels/home_orders_view_model.dart';
import '../orders/home_order_tracking_widgets.dart';
import 'home_tab_scaffold.dart';

class HomeOrdersTab extends StatefulWidget {
  const HomeOrdersTab({super.key});

  @override
  State<HomeOrdersTab> createState() => _HomeOrdersTabState();
}

class _HomeOrdersTabState extends State<HomeOrdersTab> {
  late final HomeOrdersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeOrdersViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return StreamBuilder<List<HomeUserOrder>>(
          stream: _viewModel.ordersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const HomeTabScaffold(
                title: 'My Orders',
                subtitle: 'Track delivery updates and order status',
                child: _InfoCard(
                  icon: Icons.error_outline_rounded,
                  message: 'Unable to load your orders right now.',
                ),
              );
            }

            if (!snapshot.hasData) {
              return const HomeTabScaffold(
                title: 'My Orders',
                subtitle: 'Track delivery updates and order status',
                child: _InfoCard(
                  icon: Icons.local_shipping_outlined,
                  message: 'Loading your order tracking details...',
                  isLoading: true,
                ),
              );
            }

            return HomeTabScaffold(
              title: 'My Orders',
              subtitle: 'Track order status and delivery progress',
              child: _OrdersContent(
                state: _viewModel.buildState(snapshot.data!),
                onFilterChanged: _viewModel.setFilter,
                onTrack: (order) => _openTrackSheet(context, order),
                onProductTap: (order) => Navigator.of(context).pushNamed(
                  AppRoutes.productDetails,
                  arguments: ProductDetailsPageArgs(
                    productId: order.productId,
                    productName: order.productName,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openTrackSheet(BuildContext context, HomeUserOrder order) {
    final steps = _viewModel.buildTrackSteps(order);
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
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ordered ${homeTimeAgo(order.createdAt)} - ${homeFullDate(order.createdAt)}',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
              ),
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
                        fontWeight: step.$2 ? FontWeight.w700 : FontWeight.w600,
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

class _OrdersContent extends StatelessWidget {
  const _OrdersContent({
    required this.state,
    required this.onFilterChanged,
    required this.onTrack,
    required this.onProductTap,
  });

  final HomeOrdersState state;
  final ValueChanged<HomeOrderFilter> onFilterChanged;
  final ValueChanged<HomeUserOrder> onTrack;
  final ValueChanged<HomeUserOrder> onProductTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (state.activeOrders.isNotEmpty) ...[
          _ActiveOrdersWarningBanner(count: state.activeOrders.length),
          const SizedBox(height: 8),
        ],
        HomeOrdersSummaryCard(
          total: state.totalCount,
          active: state.activeCount,
          delivered: state.deliveredCount,
          cancelled: state.cancelledCount,
        ),
        const SizedBox(height: 12),
        _OrderFilterBar(
          selected: state.selectedFilter,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 12),
        if (state.orders.isEmpty)
          const _InfoCard(
            icon: Icons.receipt_long_outlined,
            message: 'No orders yet. Place a product order to track it here.',
          )
        else if (state.filteredOrders.isEmpty)
          _InfoCard(
            icon: Icons.filter_alt_off_outlined,
            message:
                'No ${state.selectedFilter.label.toLowerCase()} orders found.',
          )
        else
          ...state.filteredOrders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HomeOrderTrackingCard(
                order: order,
                onTrack: () => onTrack(order),
                onProductTap: () => onProductTap(order),
              ),
            ),
          ),
      ],
    );
  }
}

class _OrderFilterBar extends StatelessWidget {
  const _OrderFilterBar({required this.selected, required this.onChanged});

  final HomeOrderFilter selected;
  final ValueChanged<HomeOrderFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HomeOrderFilter.values.map((filter) {
          final isSelected = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(filter.label),
              onSelected: (_) => onChanged(filter),
              showCheckmark: false,
              avatar: Icon(
                _filterIcon(filter),
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              selectedColor: const Color(0xFF007AFF),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF007AFF)
                    : const Color(0xFFDCE3EE),
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF172033),
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _filterIcon(HomeOrderFilter filter) {
    return switch (filter) {
      HomeOrderFilter.all => Icons.list_alt_outlined,
      HomeOrderFilter.active => Icons.local_shipping_outlined,
      HomeOrderFilter.delivered => Icons.check_circle_outline,
      HomeOrderFilter.cancelled => Icons.cancel_outlined,
    };
  }
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
        border: Border.all(
          color: const Color(0xFFFFCC00).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFF9500),
            size: 20,
          ),
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
  const _InfoCard({
    required this.icon,
    required this.message,
    this.isLoading = false,
  });

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
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
