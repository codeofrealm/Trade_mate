import 'package:flutter/material.dart';

import '../features/auth/data/auth_service.dart';
import '../features/auth/data/auth_user_store.dart';
import 'app_routes.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  late final Future<String> _nextRouteFuture;

  @override
  void initState() {
    super.initState();
    _nextRouteFuture = _computeNextRoute();
  }

  Future<String> _computeNextRoute() async {
    final isSignedIn = await AuthService.isSignedIn();
    if (!isSignedIn) {
      return AppRoutes.login;
    }

    await AuthService.hydrateCurrentUserProfile();

    return (AuthUserStore.role ?? 'user').toLowerCase() == 'admin'
        ? AppRoutes.admin
        : AppRoutes.home;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: _nextRouteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          final nextRoute = snapshot.data ?? AppRoutes.login;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            Navigator.of(context).pushReplacementNamed(nextRoute);
          });

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

