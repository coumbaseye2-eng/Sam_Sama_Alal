import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'auth_controller.dart';
import 'pin_dots.dart';
import 'pin_pad.dart';

class LoginPinScreen extends ConsumerStatefulWidget {
  const LoginPinScreen({super.key});

  @override
  ConsumerState<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends ConsumerState<LoginPinScreen> {
  String _pin = '';
  String? _error;
  int _failedAttempts = 0;
  int _blockedSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.primary,
                child: Text(
                  user?.initial ?? 'S',
                  style: const TextStyle(color: Colors.white, fontSize: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'Compte local',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text('Entre ton code PIN', textAlign: TextAlign.center),
              const SizedBox(height: 28),
              PinDots(length: _pin.length, hasError: _error != null),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 30),
              PinPad(
                value: _pin,
                onChanged: _blockedSeconds == 0 ? _setPin : (_) {},
                onSubmit: _blockedSeconds == 0 ? _submit : null,
              ),
              TextButton(
                onPressed: () => context.push('/forgot-pin'),
                child: const Text('PIN oublié ? Récupérer par SMS'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _setPin(String value) {
    setState(() {
      _pin = value;
      _error = null;
    });
  }

  void _submit() {
    final valid = ref.read(authControllerProvider.notifier).loginWithPin(_pin);
    if (valid) {
      context.go('/dashboard');
      return;
    }

    _failedAttempts += 1;
    if (_failedAttempts >= 3) {
      _startBlock();
      return;
    }

    setState(() {
      _pin = '';
      _error = 'Code incorrect';
    });
  }

  void _startBlock() {
    setState(() {
      _pin = '';
      _blockedSeconds = 30;
      _error = 'Trop de tentatives. Réessaie dans 30s.';
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_blockedSeconds <= 1) {
        timer.cancel();
        setState(() {
          _failedAttempts = 0;
          _blockedSeconds = 0;
          _error = null;
        });
        return;
      }
      setState(() {
        _blockedSeconds -= 1;
        _error = 'Trop de tentatives. Réessaie dans ${_blockedSeconds}s.';
      });
    });
  }
}
