import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../app/ui/glass.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/auth_user_store.dart';
import '../../data/models/admin_product.dart';
import '../widgets/dashboard/admin_completed_orders_tab.dart';
import '../widgets/dashboard/admin_overview_tab.dart';
import '../widgets/dashboard/admin_orders_tab.dart';
import '../widgets/dashboard/admin_products_tab.dart';
import '../widgets/dashboard/admin_reviews_tab.dart';
import 'admin_product_form_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;

  static const _titles = [
    'Dashboard',
    'Products',
    'Orders',
    'Customers',
    'Completed',
  ];

  void _onNavChange(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _openUpload({AdminProduct? product}) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.adminProductForm,
      arguments: AdminProductFormArgs(product: product),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<void> _openProfileSheet() async {
    final role = (AuthUserStore.role ?? 'admin').trim();
    final name = AuthUserStore.username?.trim().isNotEmpty == true
        ? AuthUserStore.username!.trim()
        : 'Admin';
    final email = AuthUserStore.email?.trim().isNotEmpty == true
        ? AuthUserStore.email!.trim()
        : 'admin@gmail.com';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF2F2F7),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF000000))),
                          const SizedBox(height: 2),
                          Text(email,
                              style: const TextStyle(
                                  color: Color(0xFF8E8E93), fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xFF34C759),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _logout(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthUserStore.username?.trim().isNotEmpty == true
        ? AuthUserStore.username!.trim()
        : 'Admin';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        automaticallyImplyLeading: false,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.3),
        ),
        actions: [
          GestureDetector(
            onTap: _openProfileSheet,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          top: false,
          child: IndexedStack(
            index: _currentIndex,
            children: [
              AdminOverviewTab(onEditTap: (product) => _openUpload(product: product)),
              AdminProductsTab(
                onUploadTap: _openUpload,
                onEditTap: (product) => _openUpload(product: product),
              ),
              const AdminOrdersTab(),
              const AdminReviewsTab(),
              const AdminCompletedOrdersTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _openUpload,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Product',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onNavChange,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: const Color(0xFF007AFF).withOpacity(0.1),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF007AFF)),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded,
                    color: Color(0xFF007AFF)),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded,
                    color: Color(0xFF007AFF)),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon:
                    Icon(Icons.people_rounded, color: Color(0xFF007AFF)),
                label: 'Customers',
              ),
              NavigationDestination(
                icon: Icon(Icons.check_circle_outline_rounded),
                selectedIcon:
                    Icon(Icons.check_circle_rounded, color: Color(0xFF007AFF)),
                label: 'Completed',
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
