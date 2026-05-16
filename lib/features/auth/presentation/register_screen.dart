import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/primary_scaffold.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _goalController = TextEditingController();
  String _activityType = 'Boutiquier';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return PrimaryScaffold(
      title: 'Créer un compte',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LinearProgressIndicator(value: 0.5),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Prénom / Nom'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Minimum 2 caractères'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Adresse mail'),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Adresse mail invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              validator: (value) => value == null || value.length < 6
                  ? 'Minimum 6 caractères'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _activityType,
              decoration: const InputDecoration(labelText: 'Type d’activité'),
              items: const [
                DropdownMenuItem(
                    value: 'Boutiquier', child: Text('Boutiquier')),
                DropdownMenuItem(
                    value: 'Vendeur ambulant', child: Text('Vendeur ambulant')),
                DropdownMenuItem(
                    value: 'Restauration', child: Text('Restauration')),
                DropdownMenuItem(value: 'Autre', child: Text('Autre')),
              ],
              onChanged: (value) =>
                  setState(() => _activityType = value ?? 'Boutiquier'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Objectif journalier (FCFA)'),
            ),
            const SizedBox(height: 28),
            if (auth.errorMessage != null) ...[
              Text(
                auth.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .registerWithEmailAndPassword(
          PendingRegistration(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            activityType: _activityType,
            dailyGoal: int.tryParse(_goalController.text.trim()) ?? 0,
          ),
        );
    if (success && mounted) {
              context.push('/create-pin');
    }
  }
}
