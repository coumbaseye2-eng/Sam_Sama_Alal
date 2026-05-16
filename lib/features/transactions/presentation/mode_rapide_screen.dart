import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import 'transaction_tile.dart';
import 'transactions_controller.dart';

class ModeRapideScreen extends ConsumerWidget {
  const ModeRapideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsControllerProvider);

    return PrimaryScaffold(
      title: 'Mode Rapide',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionCard(
            label: 'J’ai vendu',
            icon: Icons.arrow_upward,
            background: AppColors.primary,
            foreground: Colors.white,
            onTap: () => context.push('/saisie-vente'),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            label: 'J’ai dépensé',
            icon: Icons.arrow_downward,
            background: AppColors.primarySoft,
            foreground: AppColors.primary,
            onTap: () => context.push('/saisie-depense'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text('Récentes',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              TextButton(
                  onPressed: () => context.push('/historique'),
                  child: const Text('Voir tout')),
            ],
          ),
          if (transactions.isEmpty)
            const SectionCard(child: Text('Aucune transaction enregistrée.'))
          else
            ...transactions.take(3).map(TransactionTile.new),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
