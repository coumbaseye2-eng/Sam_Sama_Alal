import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/transaction_type.dart';
import 'payment_method_badge.dart';
import 'transactions_controller.dart';

class ConfirmationScreen extends ConsumerWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(latestTransactionProvider);
    final balance = ref.watch(balanceProvider);
    final isSale = transaction?.type == TransactionType.sale;
    final productName = transaction?.productName;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.check, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 22),
              Text(
                isSale ? 'Vente enregistrée !' : 'Dépense enregistrée !',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  children: [
                    Text(
                      '${isSale ? '+' : '-'}${transaction?.amount ?? 0} FCFA',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(productName ?? transaction?.category ?? 'Autre'),
                    if (isSale && transaction != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${transaction.quantity} x ${transaction.unitPrice} FCFA',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                    const SizedBox(height: 6),
                    PaymentMethodBadge(
                      method: transaction?.paymentMethod ?? 'Espèces',
                    ),
                    const Divider(height: 28),
                    Text('Nouveau solde : $balance FCFA'),
                    if (transaction?.synced == false)
                      const Text(
                        'En attente de sync',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Retour à l’accueil'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/mode-rapide'),
                child: const Text('+ Nouvelle transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
