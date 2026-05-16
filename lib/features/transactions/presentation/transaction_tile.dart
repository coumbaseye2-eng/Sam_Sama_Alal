import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/app_transaction.dart';
import '../domain/transaction_type.dart';
import 'payment_method_badge.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile(this.transaction, {super.key});

  final AppTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isSale = transaction.type == TransactionType.sale;
    final sign = isSale ? '+' : '-';
    final color = isSale ? AppColors.primary : AppColors.primaryMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  isSale ? AppColors.primary : AppColors.primarySoft,
              child: Icon(
                isSale ? Icons.arrow_upward : Icons.arrow_downward,
                color: isSale ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      PaymentMethodBadge(
                        method: transaction.paymentMethod,
                        compact: true,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${transaction.type.label} · ${_time(transaction.createdAt)}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$sign${transaction.amount} FCFA',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
