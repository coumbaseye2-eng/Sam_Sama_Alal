import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/primary_scaffold.dart';
import 'auth_controller.dart';
import 'pin_dots.dart';
import 'pin_pad.dart';

class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  String _pin = '';
  String? _firstPin;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final isConfirmation = _firstPin != null;

    return PrimaryScaffold(
      title: 'Créer ton PIN',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(value: 1),
          const SizedBox(height: 40),
          Text(
            isConfirmation
                ? 'Confirme ton PIN'
                : 'Choisis un code à 4 chiffres',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 26),
          PinDots(length: _pin.length, hasError: _error != null),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 34),
          PinPad(value: _pin, onChanged: _setPin, onSubmit: _submit),
        ],
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
    if (_firstPin == null) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
      });
      return;
    }

    if (_firstPin != _pin) {
      setState(() {
        _pin = '';
        _firstPin = null;
        _error = 'Les codes ne correspondent pas';
      });
      return;
    }

    final auth = ref.read(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    if (auth.pendingRegistration == null && auth.user != null) {
      controller.updatePin(_pin);
    } else {
      controller.completeRegistration(_pin);
    }
    context.go('/dashboard');
  }
}
