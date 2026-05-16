import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../transactions/presentation/transactions_controller.dart';
import '../../transactions/presentation/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final transactions = ref.watch(transactionsControllerProvider);
    final balance = ref.watch(balanceProvider);
    final goal = user?.dailyGoal ?? 0;
    final progress = goal <= 0 ? 0.0 : (balance / goal).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsControllerProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour ${user?.firstName ?? ''}'),
                        const Text(
                          'Tableau de bord',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/stocks'),
                    icon: const Icon(Icons.inventory_2_outlined),
                  ),
                  IconButton(
                    onPressed: () => context.push('/profil'),
                    icon: const Icon(Icons.person_outline),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Solde actuel'),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatAmount(balance)} FCFA',
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                        '${(progress * 100).round()}% de l’objectif journalier'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/mode-rapide'),
                child: const Text('Mode Rapide'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/historique'),
                child: const Text('Historique'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/carnet'),
                icon: const Icon(Icons.sticky_note_2_outlined),
                label: const Text('Carnet'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Dernières transactions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/historique'),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              if (transactions.isEmpty)
                const SectionCard(
                    child: Text('Aucune transaction pour le moment.'))
              else
                ...transactions.take(3).map(TransactionTile.new),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.push('/performance'),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Performance'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(int amount) => amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]} ',
      );
}
