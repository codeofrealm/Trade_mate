import 'package:flutter/foundation.dart';

import '../../data/home_product_service.dart';
import '../../data/models/home_user_order.dart';

class HomeOrdersViewModel extends ChangeNotifier {
  HomeOrdersViewModel({HomeProductService? productService})
    : _productService = productService ?? HomeProductService.instance;

  final HomeProductService _productService;

  HomeOrderFilter _filter = HomeOrderFilter.all;

  HomeOrderFilter get filter => _filter;

  Stream<List<HomeUserOrder>> get ordersStream =>
      _productService.streamMyOrders();

  void setFilter(HomeOrderFilter filter) {
    if (_filter == filter) {
      return;
    }
    _filter = filter;
    notifyListeners();
  }

  HomeOrdersState buildState(List<HomeUserOrder> orders) {
    final activeOrders = orders
        .where((order) => !order.isDelivered && !order.isCancelled)
        .toList();

    return HomeOrdersState(
      orders: orders,
      filteredOrders: _filter.apply(orders),
      activeOrders: activeOrders,
      totalCount: orders.length,
      activeCount: activeOrders.length,
      deliveredCount: orders.where((order) => order.isDelivered).length,
      cancelledCount: orders.where((order) => order.isCancelled).length,
      selectedFilter: _filter,
    );
  }

  List<(String, bool)> buildTrackSteps(HomeUserOrder order) {
    const steps = ['Order Placed', 'Packed', 'Shipped', 'Delivered'];
    final safeStep = order.progressStepIndex.clamp(0, steps.length - 1);
    final values = <(String, bool)>[];
    for (var i = 0; i < steps.length; i++) {
      values.add((steps[i], !order.isCancelled && i <= safeStep));
    }
    if (order.isCancelled) values.add(('Cancelled', true));
    return values;
  }
}

class HomeOrdersState {
  const HomeOrdersState({
    required this.orders,
    required this.filteredOrders,
    required this.activeOrders,
    required this.totalCount,
    required this.activeCount,
    required this.deliveredCount,
    required this.cancelledCount,
    required this.selectedFilter,
  });

  final List<HomeUserOrder> orders;
  final List<HomeUserOrder> filteredOrders;
  final List<HomeUserOrder> activeOrders;
  final int totalCount;
  final int activeCount;
  final int deliveredCount;
  final int cancelledCount;
  final HomeOrderFilter selectedFilter;
}

enum HomeOrderFilter {
  all('All'),
  active('Active'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const HomeOrderFilter(this.label);

  final String label;

  List<HomeUserOrder> apply(List<HomeUserOrder> orders) {
    return switch (this) {
      HomeOrderFilter.all => orders,
      HomeOrderFilter.active =>
        orders
            .where((order) => !order.isDelivered && !order.isCancelled)
            .toList(),
      HomeOrderFilter.delivered =>
        orders.where((order) => order.isDelivered).toList(),
      HomeOrderFilter.cancelled =>
        orders.where((order) => order.isCancelled).toList(),
    };
  }
}
