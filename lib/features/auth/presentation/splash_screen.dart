import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_logo.dart';
import 'auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      context.go(auth.isLoggedIn ? '/dashboard' : '/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(),
            SizedBox(height: 20),
            Text(
              'Sam Sama Allal',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 8),
            Text('Gestion financière simple pour commerçants'),
            SizedBox(height: 28),
            SizedBox(width: 180, child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
