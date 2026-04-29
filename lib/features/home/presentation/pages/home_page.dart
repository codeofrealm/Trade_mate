import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/ui/glass.dart';
import '../../../auth/data/auth_user_store.dart';
import '../widgets/home/home_analytics_tab.dart';
import '../widgets/home/home_cart_tab.dart';
import '../widgets/home/home_dashboard_tab.dart';
import '../widgets/home/home_floating_nav_bar.dart';
import '../widgets/home/home_orders_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  String get _displayName {
    final username = AuthUserStore.username?.trim();
    if (username == null || username.isEmpty) return 'Trader';
    return username;
  }

  void _handleTabChange(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF2F2F7),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    final pages = <Widget>[
      HomeDashboardTab(name: _displayName, onOrdersTap: () => _handleTabChange(2)),
      const HomeCartTab(),
      const HomeOrdersTab(),
      const HomeAnalyticsTab(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: GlassBackground(
          child: SafeArea(
            bottom: false,
            child: IndexedStack(index: _currentIndex, children: pages),
          ),
        ),
        bottomNavigationBar: ColoredBox(
          color: const Color(0xFFF2F2F7),
          child: HomeFloatingNavBar(
            currentIndex: _currentIndex,
            onTap: _handleTabChange,
          ),
        ),
      ),
    );
  }
}
