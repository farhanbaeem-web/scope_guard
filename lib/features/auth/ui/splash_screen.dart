import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/auth_service.dart';
import '../../clients/logic/clients_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = await AuthService.instance.authStateChanges().first;
    if (!mounted) return;
    if (user == null) {
      context.go('/login');
      return;
    }

    if (!user.isAnonymous && !user.emailVerified) {
      context.go('/verify-email');
      return;
    }

    final hasClients = await ClientsService.instance.hasClients();
    if (!mounted) return;
    context.go(hasClients ? '/' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: FlutterLogo(size: 96),
      ),
    );
  }
}
