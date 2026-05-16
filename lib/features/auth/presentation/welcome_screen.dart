import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/primary_scaffold.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 44),
          const Center(child: AppLogo(size: 76)),
          const SizedBox(height: 22),
          const Text(
            'Bienvenue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Suis tes ventes, dépenses et stocks même hors connexion.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 44),
          ElevatedButton(
            onPressed: () => context.push('/register'),
            child: const Text('Créer un compte'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('/identify'),
            child: const Text('J’ai déjà un compte'),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: const Text('Conditions d’utilisation'),
          ),
        ],
      ),
    );
  }
}
