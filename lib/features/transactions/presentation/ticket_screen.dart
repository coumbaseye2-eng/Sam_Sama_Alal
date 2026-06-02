import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_scaffold.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/receipt_service.dart';
import '../domain/transaction_type.dart';
import 'payment_method_badge.dart';
import 'transactions_controller.dart';

class TicketScreen extends ConsumerWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(latestTransactionProvider);
    final user = ref.watch(authControllerProvider).user;
    final settings = ref.watch(settingsControllerProvider);
    final balance = ref.watch(balanceProvider);
    final isSale = transaction?.type == TransactionType.sale;

    return PrimaryScaffold(
      title: 'Ticket ou facture',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionCard(
            child: Text(
              'Generer un ticket de caisse ou une facture depuis la derniere transaction.',
            ),
          ),
          const SizedBox(height: 16),
          if (transaction == null)
            const SectionCard(
              child: Text('Aucun ticket disponible pour le moment.'),
            )
          else
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${isSale ? '+' : '-'}${transaction.amount} FCFA',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(transaction.category),
                  const SizedBox(height: 6),
                  PaymentMethodBadge(method: transaction.paymentMethod),
                  const Divider(height: 28),
                  Text('Nouveau solde : $balance FCFA'),
                  if (transaction.synced == false)
                    const Text(
                      'En attente de sync',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: transaction == null
                ? null
                : () async {
                    await const ReceiptService().shareReceipt(
                      transaction: transaction,
                      balanceAfter: balance,
                      user: user,
                    );
                  },
            icon: const Icon(Icons.receipt_long),
            label: const Text('Generer et partager'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: transaction == null
                ? null
                : () async {
                    final file = await const ReceiptService().downloadReceipt(
                      transaction: transaction,
                      balanceAfter: balance,
                      user: user,
                    );
                    if (settings.notificationsEnabled) {
                      await NotificationService.instance
                          .showTicketDownloaded(file.path);
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ticket telecharge : ${file.path}'),
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.download),
            label: const Text('Generer et telecharger'),
          ),
        ],
      ),
    );
  }
}
