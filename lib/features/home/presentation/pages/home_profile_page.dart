import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/auth_user_store.dart';
import '../widgets/home/home_profile_tab.dart';

class HomeProfilePage extends StatelessWidget {
  const HomeProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthUserStore.username?.trim().isNotEmpty == true
        ? AuthUserStore.username!.trim()
        : 'Trader';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: HomeProfileTab(name: name, onLogout: () => _logout(context)),
      ),
    );
  }
}
