import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/primary_scaffold.dart';

class ForgotPinScreen extends StatelessWidget {
  const ForgotPinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      title: 'PIN oublié',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.sms_outlined, size: 72),
          const SizedBox(height: 18),
          const Text(
            'Cette fonctionnalité peut servir à récupérer ton accès par SMS.\n\n'
            'Pour le moment, tu peux revenir à la connexion ou réinitialiser ton PIN depuis ton profil.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/identify'),
            child: const Text('Retour à la connexion'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
                return;
              }
              context.go('/login-pin');
            },
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }
}

